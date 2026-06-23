<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use Yii;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use common\models\RiderRequest;
use common\models\RiderApplication;
use common\models\DeliveryAgent;
use common\models\User;
use common\models\Order;

class RiderRequestController extends ActiveController
{
    public $modelClass = '';

    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
                'Access-Control-Allow-Headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
            ],
        ];
        return $behaviors;
    }

    public function actions()
    {
        return [];
    }

    protected function getBodyParams()
    {
        $req = Yii::$app->request;
        $contentType = $req->getHeaders()->get('Content-Type');
        if ($contentType && stripos($contentType, 'application/json') !== false) {
            $rawBody = file_get_contents('php://input');
            return json_decode($rawBody, true) ?: [];
        }
        return $req->bodyParams;
    }

    public function actionCreate()
    {
        $body = $this->getBodyParams();
        $orderId = $body['order_id'] ?? null;
        if (!$orderId) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'order_id_required'];
        }

        $order = Order::findOne($orderId);
        if (!$order) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'order_not_found'];
        }

        $currentUser = $this->getCurrentUser();
        $request = new RiderRequest();
        $request->order_id = $orderId;
        $request->customer_id = $currentUser ? $currentUser->id : null;
        $request->customer_lat = $body['customer_lat'] ?? $order->customer_latitude;
        $request->customer_lng = $body['customer_lng'] ?? $order->customer_longitude;
        $request->status = 'pending';

        if ($request->save()) {
            return ['status' => 'created', 'data' => $request->toArray()];
        }
        return ['error' => 'save_failed', 'details' => $request->getErrors()];
    }

    public function actionApply()
    {
        $body = $this->getBodyParams();
        $riderRequestId = $body['rider_request_id'] ?? null;
        $priceOffer = $body['price_offer'] ?? null;

        if (!$riderRequestId) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'rider_request_id_required'];
        }

        $currentUser = $this->getCurrentUser();
        if (!$currentUser) {
            throw new \yii\web\UnauthorizedHttpException('Authentication required');
        }

        $agent = DeliveryAgent::findOne(['user_id' => $currentUser->id]);
        if (!$agent) {
            throw new \yii\web\BadRequestHttpException('Not a delivery agent');
        }

        $application = new RiderApplication();
        $application->rider_request_id = $riderRequestId;
        $application->delivery_agent_id = $agent->id;
        $application->price_offer = $priceOffer;
        $application->status = 'pending';

        if ($application->save()) {
            return ['status' => 'applied', 'data' => $application->toArray()];
        }
        return ['error' => 'apply_failed', 'details' => $application->getErrors()];
    }

    public function actionAcceptApplication()
    {
        $body = $this->getBodyParams();
        $applicationId = $body['application_id'] ?? null;

        if (!$applicationId) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'application_id_required'];
        }

        $currentUser = $this->getCurrentUser();
        if (!$currentUser) {
            throw new \yii\web\UnauthorizedHttpException('Authentication required');
        }

        $application = RiderApplication::findOne($applicationId);
        if (!$application) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'application_not_found'];
        }

        $riderRequest = RiderRequest::findOne($application->rider_request_id);
        if ($riderRequest->order->user_id !== $currentUser->id) {
            throw new \yii\web\ForbiddenHttpException('Not your order');
        }

        $application->status = 'accepted';
        $application->save(false);
        $riderRequest->status = 'accepted';
        $riderRequest->save(false);
        $riderRequest->order->delivery_agent_id = $application->delivery_agent_id;
        $riderRequest->order->status = 'accepted';
        $riderRequest->order->save(false);

        return ['status' => 'accepted'];
    }

    public function actionListApplications($riderRequestId)
    {
        $currentUser = $this->getCurrentUser();
        $riderRequest = RiderRequest::findOne($riderRequestId);
        if (!$riderRequest) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'request_not_found'];
        }
        if ($currentUser && $riderRequest->order->user_id !== $currentUser->id) {
            throw new \yii\web\ForbiddenHttpException('Not your order');
        }

        $applications = RiderApplication::find()
            ->where(['rider_request_id' => $riderRequestId, 'status' => 'pending'])
            ->with(['deliveryAgent.user'])
            ->all();

        return $applications;
    }

    protected function getCurrentUser()
    {
        $request = Yii::$app->request;
        $authHeader = $request->getHeaders()->get('Authorization');
        if (!$authHeader || !preg_match('/Bearer\s+(.*)/', $authHeader, $matches)) {
            return null;
        }
        $token = $matches[1];
        $secret = getenv('JWT_SECRET') ?: (Yii::$app->params['jwtSecret'] ?? 'bitedash_secret_change_me');
        try {
            $decoded = JWT::decode($token, new Key($secret, 'HS256'));
        } catch (\Exception $e) {
            return null;
        }
        if (empty($decoded->sub)) return null;
        return User::findOne($decoded->sub);
    }
}