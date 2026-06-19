<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use common\models\Restaurant;

/**
 * @OA\Tag(name="Restaurant", description="Operations related to restaurants")
 */
class RestaurantController extends ActiveController
{
    public $modelClass = 'common\models\Restaurant';

    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => \yii\filters\Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
            ],
        ];
        return $behaviors;
    }

    public function actions()
    {
        $actions = parent::actions();
        return $actions;
    }
}
