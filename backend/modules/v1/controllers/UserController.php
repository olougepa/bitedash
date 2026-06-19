<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use common\models\User;

/**
 * @OA\Tag(name="User", description="User operations")
 */
class UserController extends ActiveController
{
    public $modelClass = 'common\models\User';

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
}
