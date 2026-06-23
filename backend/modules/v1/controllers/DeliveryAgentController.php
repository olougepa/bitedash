<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use yii\web\BadRequestHttpException;
use yii\web\UnauthorizedHttpException;
use common\models\DeliveryAgent;
use common\models\Order;

class DeliveryAgentController extends ActiveController
{
    public $modelClass = 'common\models\DeliveryAgent';

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
        $req = \Yii::$app->request;
        $contentType = $req->getHeaders()->get('Content-Type');
        if ($contentType && stripos($contentType, 'application/json') !== false) {
            $rawBody = file_get_contents('php://input');
            return json_decode($rawBody, true) ?: [];
        }
        return $req->bodyParams;
    }

    public function actionLocation()
    {
        $user = $this->getCurrentUser();
        if (!$user) {
            throw new UnauthorizedHttpException('Authentication required');
        }

        $agent = DeliveryAgent::findOne(['user_id' => $user->id]);
        if (!$agent) {
            throw new BadRequestHttpException('Not a delivery agent');
        }

        $body = $this->getBodyParams();
        $agent->latitude = $body['latitude'] ?? null;
        $agent->longitude = $body['longitude'] ?? null;
        $agent->last_seen_at = new \yii\db\Expression('NOW()');

        if ($agent->save()) {
            return ['status' => 'updated', 'latitude' => $agent->latitude, 'longitude' => $agent->longitude];
        }

        return $agent->getErrors();
    }

    public function actionNearby()
    {
        $lat = \Yii::$app->request->get('lat');
        $lng = \Yii::$app->request->get('lng');

        $agents = DeliveryAgent::find()
            ->alias('da')
            ->joinWith('user u')
            ->where(['u.status' => 'active', 'da.is_active' => 1])
            ->limit(10)
            ->all();

        return $agents;
    }

    protected function getCurrentUser()
    {
        $request = \Yii::$app->request;
        $authHeader = $request->getHeaders()->get('Authorization');
        if (!$authHeader || !preg_match('/Bearer\s+(.*)/', $authHeader, $matches)) {
            return null;
        }

        $token = $matches[1];
        $secret = getenv('JWT_SECRET') ?: (\Yii::$app->params['jwtSecret'] ?? 'bitedash_secret_change_me');
        try {
            $decoded = \Firebase\JWT\JWT::decode($token, new \Firebase\JWT\Key($secret, 'HS256'));
        } catch (\Exception $e) {
            return null;
        }

        if (empty($decoded->sub)) {
            return null;
        }

        return \common\models\User::findOne($decoded->sub);
    }
}