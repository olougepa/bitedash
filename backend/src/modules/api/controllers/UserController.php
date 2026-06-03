<?php
namespace app\modules\api\controllers;

use yii\rest\ActiveController;

/**
 * @OA\Tag(name="User", description="User operations")
 */
class UserController extends ActiveController
{
    public $modelClass = 'app\\models\\User';
}
