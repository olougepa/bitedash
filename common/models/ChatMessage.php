<?php
namespace common\models;

use yii\db\ActiveRecord;

class ChatMessage extends ActiveRecord
{
    public static function tableName()
    {
        return 'chat_messages';
    }

    public function rules()
    {
        return [
            [['order_id', 'sender_id', 'receiver_id', 'message'], 'required'],
            [['order_id', 'sender_id', 'receiver_id'], 'integer'],
            [['message'], 'string'],
            [['created_at'], 'safe'],
        ];
    }
}