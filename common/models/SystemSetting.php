<?php
namespace common\models;

use yii\db\ActiveRecord;

class SystemSetting extends ActiveRecord
{
    public static function tableName()
    {
        return 'system_settings';
    }

    public function rules()
    {
        return [
            [['setting_key', 'setting_value'], 'required'],
            [['setting_key'], 'string', 'max' => 100],
            [['setting_value'], 'string'],
        ];
    }
}