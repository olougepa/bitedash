<?php
namespace app\models;

use yii\db\ActiveRecord;

class User extends ActiveRecord
{
    public static function tableName()
    {
        return 'users';
    }

    public function rules()
    {
        return [
            [['email', 'password_hash', 'role', 'status'], 'required'],
            ['email', 'email'],
            ['email', 'unique'],
            ['role', 'in', 'range' => ['customer', 'restaurant_owner', 'delivery_agent', 'admin']],
            ['status', 'in', 'range' => ['pending', 'active', 'suspended', 'deleted']],
        ];
    }

    public function fields()
    {
        $fields = parent::fields();
        // remove sensitive fields
        unset($fields['password_hash']);
        unset($fields['password_hashed']);
        return $fields;
    }
}
