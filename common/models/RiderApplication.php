<?php
namespace common\models;

use yii\db\ActiveRecord;

class RiderApplication extends ActiveRecord
{
    public static function tableName()
    {
        return 'rider_applications';
    }

    public function rules()
    {
        return [
            [['rider_request_id', 'delivery_agent_id'], 'required'],
            ['rider_request_id', 'integer'],
            ['delivery_agent_id', 'integer'],
            ['price_offer', 'number', 'min' => 0],
            ['status', 'in', 'range' => ['pending', 'accepted', 'rejected']],
        ];
    }

    public function getRiderRequest()
    {
        return $this->hasOne(RiderRequest::class, ['id' => 'rider_request_id']);
    }

    public function getDeliveryAgent()
    {
        return $this->hasOne(DeliveryAgent::class, ['id' => 'delivery_agent_id']);
    }
}