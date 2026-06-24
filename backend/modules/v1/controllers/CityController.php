<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use common\models\City;
use Yii;

class CityController extends ActiveController
{
    public $modelClass = 'common\models\City';

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
        return $behaviors;
    }

    protected function verbs()
    {
        return [
            'index' => ['GET'],
            'create' => ['POST'],
            'update' => ['PUT', 'PATCH'],
            'delete' => ['DELETE'],
        ];
    }

    public function actionCreate()
    {
        $body = $this->getBodyParams();
        $city = new City();
        $city->load($body, '');
        if ($city->save()) {
            Yii::$app->db->createCommand()->insert('notifications', [
                'user_id' => null,
                'category' => 'admin',
                'title' => 'City Added',
                'message' => 'City ' . $city->name . ' has been added to the system',
                'created_at' => date('Y-m-d H:i:s'),
            ])->execute();
            return $city;
        }
        return $city->getErrors();
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
}