<?php
namespace common\models;

use yii\db\ActiveRecord;

class MenuItem extends ActiveRecord
{
    public static function tableName()
    {
        return 'menu_items';
    }

    public function rules()
    {
        return [
            [['restaurant_id', 'name', 'price'], 'required'],
            ['name', 'string', 'max' => 255],
            [['price', 'rating', 'quantity', 'stock_quantity'], 'number'],
            ['is_available', 'boolean'],
            ['photo_url', 'string', 'max' => 512],
            [['quantity', 'stock_quantity'], 'default', 'value' => null],
        ];
    }
}