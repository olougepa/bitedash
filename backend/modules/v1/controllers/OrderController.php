<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use Yii;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use common\models\Order;
use common\models\Restaurant;
use common\models\User;
use common\models\DeliveryAgent;

class OrderController extends ActiveController
{
    public $modelClass = 'common\models\Order';

    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['POST', 'GET', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
                'Access-Control-Allow-Headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
            ],
        ];
        return $behaviors;
    }

    protected function verbs()
    {
        return [
            'index' => ['GET', 'POST'],
            'create' => ['POST'],
            'update' => ['PUT', 'PATCH'],
            'delete' => ['DELETE'],
            'customer-location' => ['PATCH'],
            'tracking' => ['GET'],
        ];
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

    public function actions()
    {
        $actions = parent::actions();
        $actions['index']['prepareDataProvider'] = [$this, 'actionIndex'];
        return $actions;
    }

    public function actionIndex()
    {
        $request = Yii::$app->request;
        $query = Order::find()->with(['restaurant', 'deliveryAgent']);

        $status = $request->get('status');
        if ($status) {
            $query->andWhere(['status' => $status]);
        }

        $restaurantId = $request->get('restaurant_id');
        if ($restaurantId) {
            $query->andWhere(['restaurant_id' => $restaurantId]);
        }

        $currentUser = $this->getCurrentUser();
        if ($currentUser) {
            if ($currentUser->role === 'restaurant_owner') {
                $ownedRestaurantIds = Restaurant::find()
                    ->select('id')
                    ->where(['owner_id' => $currentUser->id])
                    ->column();
                $query->andWhere(['restaurant_id' => $ownedRestaurantIds]);
            } elseif ($currentUser->role === 'customer') {
                $query->andWhere(['user_id' => $currentUser->id]);
            } elseif ($currentUser->role === 'delivery_agent') {
                $agent = DeliveryAgent::findOne(['user_id' => $currentUser->id]);
                if ($agent) {
                    $query->andWhere(['delivery_agent_id' => $agent->id]);
                }
            }
        }

        return $query->orderBy(['created_at' => SORT_DESC])->all();
    }

    public function actionCreate()
    {
        $body = $this->getBodyParams();
        $order = new Order();
        $order->load($body, '');

        $currentUser = $this->getCurrentUser();
        if ($currentUser && empty($order->user_id)) {
            $order->user_id = $currentUser->id;
        }

        if (!$currentUser && empty($order->guest_token)) {
            $order->guest_token = bin2hex(random_bytes(16));
        }

        if (isset($body['payment_stub']) && is_array($body['payment_stub'])) {
            $order->payment_stub = json_encode($body['payment_stub']);
        }

        if ($order->save()) {
            return $order;
        }

        Yii::$app->response->statusCode = 422;
        return $order->getErrors();
    }

    public function actionCustomerLocation($id)
    {
        $order = Order::findOne($id);
        if (!$order) {
            throw new \yii\web\NotFoundHttpException('Order not found');
        }

        $currentUser = $this->getCurrentUser();
        if ($currentUser && $order->user_id !== $currentUser->id) {
            throw new \yii\web\ForbiddenHttpException('Not your order');
        }

        $body = $this->getBodyParams();
        $order->customer_latitude = $body['latitude'] ?? null;
        $order->customer_longitude = $body['longitude'] ?? null;

        if ($order->save()) {
            return ['status' => 'updated'];
        }

        return $order->getErrors();
    }

    public function actionTracking($id)
    {
        $order = Order::findOne($id);
        if (!$order) {
            throw new \yii\web\NotFoundHttpException('Order not found');
        }

        $currentUser = $this->getCurrentUser();
        if ($currentUser) {
            if ($currentUser->role === 'restaurant_owner') {
                $ownedRestaurantIds = Restaurant::find()->select('id')->where(['owner_id' => $currentUser->id])->column();
                if (!in_array($order->restaurant_id, $ownedRestaurantIds)) {
                    throw new \yii\web\ForbiddenHttpException('Not your restaurant order');
                }
            } elseif ($currentUser->role === 'customer' && $order->user_id !== $currentUser->id) {
                throw new \yii\web\ForbiddenHttpException('Not your order');
            } elseif ($currentUser->role === 'delivery_agent') {
                $agent = DeliveryAgent::findOne(['user_id' => $currentUser->id]);
                if (!$agent || $order->delivery_agent_id !== $agent->id) {
                    throw new \yii\web\ForbiddenHttpException('Not your delivery');
                }
            }
        }

        return $order;
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

        if (empty($decoded->sub)) {
            return null;
        }

        return User::findOne($decoded->sub);
    }
}