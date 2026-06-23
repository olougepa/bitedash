<?php
namespace common\models;

use yii\db\ActiveRecord;

class Coupon extends ActiveRecord
{
    public static function tableName()
    {
        return 'coupons';
    }

    public function rules()
    {
        return [
            [['restaurant_id', 'code', 'valid_from', 'valid_until'], 'required'],
            ['restaurant_id', 'integer'],
            ['code', 'string', 'max' => 100],
            ['description', 'string'],
            ['discount_percent', 'number', 'min' => 0, 'max' => 100],
            ['discount_amount', 'number', 'min' => 0],
            ['min_order_amount', 'number', 'min' => 0],
            ['max_uses', 'integer', 'min' => 0],
            ['used_count', 'integer', 'min' => 0],
            ['is_active', 'boolean'],
        ];
    }

    public function getRestaurant()
    {
        return $this->hasOne(Restaurant::class, ['id' => 'restaurant_id']);
    }
}