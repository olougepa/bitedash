<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use common\models\KycRecord;

class KycController extends ActiveController
{
    public $modelClass = 'common\models\KycRecord';

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
}