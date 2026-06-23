<?php
namespace common\models;

use yii\db\ActiveRecord;

class Restaurant extends ActiveRecord
{
    public static function tableName()
    {
        return 'restaurants';
    }

    public function rules()
    {
        return [
            [['owner_id', 'name', 'status'], 'required'],
            ['name', 'string', 'max' => 255],
            ['status', 'in', 'range' => ['draft', 'pending', 'active', 'suspended', 'closed']],
            [['latitude', 'longitude'], 'number'],
        ];
    }

    public function fields()
    {
        $fields = parent::fields();
        $fields['is_verified'] = function () {
            $user = User::findOne($this->owner_id);
            return $user && $user->status === 'active' && $this->status === 'active';
        };
        return $fields;
    }
}