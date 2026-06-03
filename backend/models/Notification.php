<?php
namespace app\models;

use yii\db\ActiveRecord;

class Notification extends ActiveRecord
{
    public static function tableName()
    {
        return 'notifications';
    }

    public function rules()
    {
        return [
            [['title', 'message', 'category'], 'required'],
            ['category', 'in', 'range' => ['customer', 'restaurant_owner', 'delivery_agent', 'admin', 'all']],
            [['user_id'], 'integer'],
            [['is_read'], 'boolean'],
        ];
    }
}
