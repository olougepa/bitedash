<?php
namespace common\models;

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
            [['password_hash', 'role', 'status'], 'required'],
            [['email', 'phone'], 'string'],
            ['city_id', 'integer'],
            ['email', 'email'],
            ['phone', 'string', 'max' => 50],
            ['role', 'in', 'range' => ['customer', 'restaurant_owner', 'delivery_agent', 'admin']],
            ['status', 'in', 'range' => ['pending', 'active', 'suspended', 'deleted']],
        ];
    }

    public function fields()
    {
        $fields = parent::fields();
        unset($fields['password_hash']);
        unset($fields['password_hashed']);
        return $fields;
    }

    public static function findByUsername($username)
    {
        return static::findOne(['or', ['email' => $username], ['phone' => $username]]);
    }
}