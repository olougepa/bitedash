<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use Yii;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use common\models\Coupon;
use common\models\Restaurant;
use common\models\User;
use common\models\DeliveryAgent;

class CouponController extends ActiveController
{
    public $modelClass = 'common\models\Coupon';

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

    protected function verbs()
    {
        return [
            'index' => ['GET', 'POST'],
            'view' => ['GET'],
            'create' => ['POST'],
            'update' => ['PUT', 'PATCH'],
            'delete' => ['DELETE'],
            'check' => ['GET'],
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

    public function actionIndex()
    {
        $currentUser = $this->getCurrentUser();
        $query = Coupon::find();

        $restaurantId = Yii::$app->request->get('restaurant_id');
        $agentId = Yii::$app->request->get('agent_id');

        if ($restaurantId) {
            $query->andWhere(['restaurant_id' => $restaurantId]);
        }

        if ($agentId) {
            $query->andWhere(['delivery_agent_id' => $agentId]);
        }

        if ($currentUser && $currentUser->role === 'restaurant_owner') {
            $ownedRestaurantIds = Restaurant::find()->select('id')->where(['owner_id' => $currentUser->id])->column();
            $query->andWhere(['restaurant_id' => $ownedRestaurantIds]);
        }

        if ($currentUser && $currentUser->role === 'delivery_agent') {
            $agent = DeliveryAgent::findOne(['user_id' => $currentUser->id]);
            if ($agent) {
                $query->andWhere(['delivery_agent_id' => $agent->id]);
            }
        }

        return $query->orderBy(['created_at' => SORT_DESC])->all();
    }

    public function actionCheck($code)
    {
        $coupon = Coupon::findOne(['code' => $code, 'is_active' => 1]);
        if (!$coupon) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'invalid_coupon'];
        }

        if ($coupon->valid_until < date('Y-m-d H:i:s')) {
            return ['error' => 'coupon_expired'];
        }

        if ($coupon->max_uses > 0 && $coupon->used_count >= $coupon->max_uses) {
            return ['error' => 'coupon_exhausted'];
        }

        return ['valid' => true, 'data' => $coupon->toArray()];
    }

    public function actionCreate()
    {
        $currentUser = $this->getCurrentUser();
        $body = $this->getBodyParams();

        $coupon = new Coupon();

        if ($currentUser && $currentUser->role === 'restaurant_owner') {
            $restaurant = Restaurant::findOne(['owner_id' => $currentUser->id]);
            if ($restaurant) {
                $coupon->restaurant_id = $restaurant->id;
            }
        } elseif ($currentUser && $currentUser->role === 'delivery_agent') {
            $agent = DeliveryAgent::findOne(['user_id' => $currentUser->id]);
            if ($agent) {
                $coupon->delivery_agent_id = $agent->id;
            }
        }

        $coupon->code = $body['code'] ?? '';
        $coupon->description = $body['description'] ?? '';
        $coupon->discount_percent = $body['discount_percent'] ?? null;
        $coupon->discount_amount = $body['discount_amount'] ?? null;
        $coupon->valid_from = $body['valid_from'] ?? date('Y-m-d H:i:s');
        $coupon->valid_until = $body['valid_until'] ?? date('Y-m-d H:i:s', strtotime('+30 days'));
        $coupon->is_active = $body['is_active'] ?? 1;
        $coupon->min_order_amount = $body['min_order_amount'] ?? 0;
        $coupon->max_uses = $body['max_uses'] ?? 0;

        if ($coupon->save()) {
            return $coupon->toArray();
        }

        Yii::$app->response->statusCode = 422;
        return $coupon->getErrors();
    }

    public function actionUpdate($id)
    {
        $coupon = Coupon::findOne($id);
        if (!$coupon) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'not_found'];
        }

        $body = $this->getBodyParams();
        
        $coupon->code = $body['code'] ?? $coupon->code;
        $coupon->description = $body['description'] ?? $coupon->description;
        $coupon->discount_percent = $body['discount_percent'] ?? $coupon->discount_percent;
        $coupon->discount_amount = $body['discount_amount'] ?? $coupon->discount_amount;
        $coupon->valid_from = $body['valid_from'] ?? $coupon->valid_from;
        $coupon->valid_until = $body['valid_until'] ?? $coupon->valid_until;
        $coupon->is_active = $body['is_active'] ?? $coupon->is_active;
        $coupon->min_order_amount = $body['min_order_amount'] ?? $coupon->min_order_amount;
        $coupon->max_uses = $body['max_uses'] ?? $coupon->max_uses;

        if ($coupon->save()) {
            return $coupon->toArray();
        }

        Yii::$app->response->statusCode = 422;
        return $coupon->getErrors();
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