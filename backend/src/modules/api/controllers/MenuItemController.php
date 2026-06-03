<?php
namespace app\modules\api\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;

/**
 * @OA\Tag(name="MenuItem", description="Menu items and menu management")
 */
class MenuItemController extends ActiveController
{
    public $modelClass = 'app\\models\\MenuItem';

    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
                'Access-Control-Allow-Credentials' => true,
            ],
        ];
        return $behaviors;
    }
}
