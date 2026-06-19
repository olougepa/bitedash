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
            [['price', 'rating'], 'number'],
            ['is_available', 'boolean'],
        ];
    }
}
