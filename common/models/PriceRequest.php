<?php
namespace common\models;

use yii\db\ActiveRecord;

class PriceRequest extends ActiveRecord
{
    public static function tableName()
    {
        return 'price_requests';
    }

    public function rules()
    {
        return [
            [['delivery_agent_id', 'proposed_price'], 'required'],
            [['delivery_agent_id'], 'integer'],
            [['proposed_price'], 'number'],
            [['admin_remark'], 'string'],
            [['status'], 'in', 'range' => ['pending', 'approved', 'rejected']],
        ];
    }

    public function getDeliveryAgent()
    {
        return $this->hasOne(DeliveryAgent::class, ['id' => 'delivery_agent_id']);
    }
}