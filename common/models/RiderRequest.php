<?php
namespace common\models;

use yii\db\ActiveRecord;

class RiderRequest extends ActiveRecord
{
    public static function tableName()
    {
        return 'rider_requests';
    }

    public function rules()
    {
        return [
            [['order_id'], 'required'],
            ['order_id', 'integer'],
            ['customer_id', 'integer'],
            ['status', 'in', 'range' => ['pending', 'accepted', 'cancelled']],
            [['customer_lat', 'customer_lng'], 'number'],
        ];
    }

    public function getOrder()
    {
        return $this->hasOne(Order::class, ['id' => 'order_id']);
    }

    public function getCustomer()
    {
        return $this->hasOne(User::class, ['id' => 'customer_id']);
    }

    public function getApplications()
    {
        return $this->hasMany(RiderApplication::class, ['rider_request_id' => 'id']);
    }
}