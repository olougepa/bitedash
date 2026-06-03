<?php
namespace app\models;

use yii\db\ActiveRecord;

class Order extends ActiveRecord
{
    public static function tableName()
    {
        return 'orders';
    }

    public function rules()
    {
        return [
            [['restaurant_id', 'order_type', 'status', 'total'], 'required'],
            ['user_id', 'integer'],
            ['guest_email', 'email'],
            [['guest_email', 'guest_token'], 'string', 'max' => 255],
            ['payment_stub', 'string'],
            ['order_type', 'in', 'range' => ['delivery', 'pickup', 'reservation']],
            ['status', 'in', 'range' => ['pending', 'accepted', 'preparing', 'picked_up', 'delivering', 'completed', 'cancelled', 'failed']],
            [['sub_total', 'delivery_fee', 'tax', 'discount', 'total'], 'number'],
        ];
    }
}
