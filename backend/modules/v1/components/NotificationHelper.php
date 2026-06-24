<?php
namespace backend\modules\v1\components;

use Yii;
use common\models\Notification;
use common\models\User;

class NotificationHelper
{
    public static function create($userId, $category, $title, $message, $link = null)
    {
        Yii::$app->db->createCommand()->insert('notifications', [
            'user_id' => $userId,
            'category' => $category,
            'title' => $title,
            'message' => $message,
            'link' => $link,
            'created_at' => date('Y-m-d H:i:s'),
        ])->execute();
    }

    public static function createForRole($role, $title, $message, $link = null)
    {
        $users = User::find()->where(['role' => $role, 'status' => 'active'])->all();
        foreach ($users as $user) {
            self::create($user->id, $role, $title, $message, $link);
        }
    }

    public static function createForUserRoles($roles, $title, $message, $link = null)
    {
        foreach ($roles as $role) {
            self::createForRole($role, $title, $message, $link);
        }
    }
}