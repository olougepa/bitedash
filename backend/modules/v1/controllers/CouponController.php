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
        $coupon->load($body, '');

        // Admin can create coupons for any target without restrictions
        if ($currentUser && $currentUser->role === 'admin') {
            // Allow admin to create global coupons or assign to any restaurant/agent
        } elseif ($currentUser && $currentUser->role === 'restaurant_owner') {
            $restaurantId = $body['restaurant_id'] ?? null;
            $ownedRestaurantIds = Restaurant::find()->select('id')->where(['owner_id' => $currentUser->id])->column();
            if (!in_array($restaurantId, $ownedRestaurantIds)) {
                throw new \yii\web\ForbiddenHttpException('Not your restaurant');
            }
        }

        if ($coupon->save()) {
            // Create notification
            Yii::$app->db->createCommand()->insert('notifications', [
                'user_id' => null,
                'category' => $coupon->restaurant_id ? 'restaurant_owner' : ($coupon->delivery_agent_id ? 'delivery_agent' : 'all'),
                'title' => 'New Coupon Created',
                'message' => 'Coupon ' . $coupon->code . ' has been created. ' . ($coupon->discount_percent ? $coupon->discount_percent . '% off' : '$' . $coupon->discount_amount . ' off'),
                'created_at' => date('Y-m-d H:i:s'),
            ])->execute();
            return $coupon;
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