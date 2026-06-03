<?php
namespace app\modules\api\controllers;

use yii\rest\ActiveController;

/**
 * @OA\Tag(name="DeliveryAgent", description="Delivery agent operations and tracking")
 */
class DeliveryAgentController extends ActiveController
{
    public $modelClass = 'app\\models\\DeliveryAgent';
}
