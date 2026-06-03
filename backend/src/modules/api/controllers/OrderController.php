<?php
namespace app\modules\api\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use Yii;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use app\models\Order;
use app\models\Restaurant;
use app\models\User;

/**
 * @OA\Tag(name="Order", description="Order creation and management")
 */
class OrderController extends ActiveController
{
    public $modelClass = 'app\\models\\Order';

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
        $query = Order::find();

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
