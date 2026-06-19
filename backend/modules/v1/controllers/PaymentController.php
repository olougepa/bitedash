<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use common\models\Payment;

/**
 * @OA\Tag(name="Payment", description="Payments and transactions")
 */
class PaymentController extends ActiveController
{
    public $modelClass = 'common\models\Payment';

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
