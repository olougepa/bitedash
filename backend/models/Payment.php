<?php
namespace app\models;

use yii\db\ActiveRecord;

class Payment extends ActiveRecord
{
    public static function tableName()
    {
        return 'payments';
    }

    public function rules()
    {
        return [
            [['order_id', 'user_id', 'amount', 'currency', 'status'], 'required'],
            ['status', 'in', 'range' => ['pending', 'paid', 'failed', 'refunded']],
            [['amount'], 'number'],
        ];
    }
}
