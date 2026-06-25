<?php
namespace common\models;

use yii\db\ActiveRecord;

class City extends ActiveRecord
{
    public static function tableName()
    {
        return 'cities';
    }

    public function rules()
    {
        return [
            [['name', 'country'], 'required'],
            [['name', 'country'], 'string', 'max' => 100],
            [['latitude', 'longitude'], 'number'],
            [['latitude', 'longitude'], 'safe'],
        ];
    }
}