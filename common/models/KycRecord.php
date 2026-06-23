<?php
namespace common\models;

use yii\db\ActiveRecord;

class KycRecord extends ActiveRecord
{
    public static function tableName()
    {
        return 'kyc_records';
    }

    public function rules()
    {
        return [
            [['user_id', 'entity_type', 'document_type'], 'required'],
            ['entity_type', 'in', 'range' => ['user', 'restaurant', 'delivery_agent']],
            ['document_type', 'in', 'range' => ['id_card', 'passport', 'driver_license', 'business_license']],
            ['status', 'in', 'range' => ['pending', 'approved', 'rejected']],
        ];
    }

    public function fields()
    {
        $fields = parent::fields();
        unset($fields['document_image_url']);
        return $fields;
    }

    public function getUser()
    {
        return $this->hasOne(User::class, ['id' => 'user_id']);
    }
}