<?php
namespace backend\modules\v1\controllers;

use Yii;
use yii\rest\ActiveController;
use yii\filters\Cors;

class AdController extends ActiveController
{
    public $modelClass = 'common\models\Ad';

    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['GET', 'POST', 'OPTIONS'],
                'Access-Control-Allow-Headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
            ],
        ];
        return $behaviors;
    }
}