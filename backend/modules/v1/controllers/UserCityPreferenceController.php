<?php
namespace backend\modules\v1\controllers;

use yii\rest\Controller;
use yii\filters\auth\HttpBearerAuth;
use Yii;

class UserCityPreferenceController extends Controller
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => \yii\filters\Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
                'Access-Control-Allow-Headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
            ],
        ];
        $behaviors['authenticator'] = [
            'class' => HttpBearerAuth::class,
        ];
        return $behaviors;
    }

    public function actionCreate()
    {
        $params = Yii::$app->getRequest()->getBodyParams();
        $cityId = $params['city_id'] ?? null;
        if (!$cityId) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'city_id required'];
        }
        $userId = Yii::$app->user->id;
        if (!$userId) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'unauthenticated'];
        }
        Yii::$app->db->createCommand()->upsert('user_city_preferences', [
            'user_id' => $userId,
            'city_id' => $cityId,
            'created_at' => date('Y-m-d H:i:s'),
        ], ['city_id' => $cityId], ['user_id'])->execute();
        return ['success' => true];
    }

    public function actionUpdate()
    {
        $params = Yii::$app->getRequest()->getBodyParams();
        $cityId = $params['city_id'] ?? null;
        $userId = Yii::$app->user->id;
        if (!$userId) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'unauthenticated'];
        }
        Yii::$app->db->createCommand()->upsert('user_city_preferences', [
            'user_id' => $userId,
            'city_id' => $cityId,
            'created_at' => date('Y-m-d H:i:s'),
        ], ['city_id' => $cityId], ['user_id'])->execute();
        return ['success' => true];
    }

    public function actionIndex()
    {
        $userId = Yii::$app->user->id;
        if (!$userId) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'unauthenticated'];
        }
        $pref = Yii::$app->db->createCommand('SELECT * FROM user_city_preferences WHERE user_id = :uid')
            ->bindValue(':uid', $userId)
            ->queryOne();
        return $pref ?: [];
    }

    protected function verbs()
    {
        return [
            'create' => ['POST'],
            'update' => ['PUT', 'PATCH'],
            'index' => ['GET'],
        ];
    }
}
