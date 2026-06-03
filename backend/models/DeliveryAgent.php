<?php
namespace app\models;

use yii\db\ActiveRecord;

class DeliveryAgent extends ActiveRecord
{
    public static function tableName()
    {
        return 'delivery_agents';
    }

    public function rules()
    {
        return [
            [['user_id', 'vehicle_type'], 'required'],
            ['vehicle_type', 'in', 'range' => ['bike', 'car', 'taxi', 'scooter']],
            ['rating', 'number'],
            ['is_active', 'boolean'],
        ];
    }
}
