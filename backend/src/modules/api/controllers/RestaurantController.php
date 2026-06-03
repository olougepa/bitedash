<?php
namespace app\modules\api\controllers;

use yii\rest\ActiveController;

/**
 * @OA\Tag(name="Restaurant", description="Operations related to restaurants")
 */
class RestaurantController extends ActiveController
{
    public $modelClass = 'app\\models\\Restaurant';

    public function actions()
    {
        $actions = parent::actions();
        return $actions;
    }
}
