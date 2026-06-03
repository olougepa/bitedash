<?php
namespace app\modules\api\controllers;

use yii\rest\ActiveController;

/**
 * @OA\Tag(name="Payment", description="Payments and transactions")
 */
class PaymentController extends ActiveController
{
    public $modelClass = 'app\\models\\Payment';
}
