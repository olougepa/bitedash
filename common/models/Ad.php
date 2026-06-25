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
            [['owner_id', 'agent_id', 'duration_days'], 'integer'],
            [['description', 'admin_remark'], 'string'],
            [['budget'], 'number'],
            [['start_date', 'end_date', 'created_at'], 'safe'],
            [['status'], 'default', 'value' => 'pending'],
            [['duration_days'], 'default', 'value' => 7],
        ];
    }

    public function fields()
    {
        $fields = parent::fields();
        $user = null;
        if ($this->owner_id) {
            $userModel = User::findOne($this->owner_id);
            $user = $userModel ? $userModel->full_name : null;
        }
        $agentName = null;
        if ($this->agent_id) {
            $agent = DeliveryAgent::findOne($this->agent_id);
            $agentName = $agent ? $agent->agency_name : null;
        }
        $fields['requester_name'] = $user ?? $agentName ?? 'Unknown';
        return $fields;
    }
}