<?php
namespace common\models;

use yii\db\ActiveRecord;

class Ad extends ActiveRecord
{
    public static function tableName()
    {
        return 'ads';
    }

    public function rules()
    {
        return [
            [['title', 'target_type'], 'required'],
            [['owner_id', 'agent_id'], 'integer'],
            [['description'], 'string'],
            [['budget'], 'number'],
            [['start_date', 'end_date', 'created_at'], 'safe'],
            [['status'], 'default', 'value' => 'pending'],
        ];
    }
}