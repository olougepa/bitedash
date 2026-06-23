<?php
namespace common\models;

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
            [['latitude', 'longitude'], 'number'],
        ];
    }

    public function getUser()
    {
        return $this->hasOne(User::class, ['id' => 'user_id']);
    }

    public function fields()
    {
        $fields = parent::fields();
        $fields['full_name'] = function () {
            return $this->user ? $this->user->full_name : null;
        };
        $fields['phone'] = function () {
            return $this->user ? $this->user->phone : null;
        };
        return $fields;
    }
}