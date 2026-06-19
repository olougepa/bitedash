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

/**
 * @OA\Tag(name="Order", description="Order creation and management")
 */
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
                'Access-Control-Allow-Credentials' => true,
            ],
        ];
        return $behaviors;
    }

    public function actions()
    {
        $actions = parent::actions();
        return $actions;
    }

    /**
     * @OA\Get(
     *   path="/orders",
     *   summary="List orders",
     *   @OA\Parameter(name="status", in="query", @OA\Schema(type="string")),
     *   @OA\Parameter(name="restaurant_id", in="query", @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="List of orders")
     * )
     */
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

    /**
     * @OA\Post(
     *   path="/orders",
     *   summary="Create order",
     *   @OA\RequestBody(required=true, @OA\MediaType(mediaType="application/json")),
     *   @OA\Response(response=201, description="Created order"),
     *   @OA\Response(response=422, description="Validation failed")
     * )
     */
    public function actionCreate()
    {
        $body = Yii::$app->request->post();
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

    /**
     * Update customer location for an order
     * @OA\Patch(path="/order/{id}/customer-location", summary="Update customer location for tracking")
     */
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

        $body = Yii::$app->request->getBodyParams();
        $order->customer_latitude = $body['latitude'] ?? null;
        $order->customer_longitude = $body['longitude'] ?? null;

        if ($order->save()) {
            return ['status' => 'updated'];
        }

        return $order->getErrors();
    }

    /**
     * Get order with live tracking data
     * @OA\Get(path="/order/{id}/tracking", summary="Get order tracking info")
     */
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