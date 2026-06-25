<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use common\models\KycRecord;
use common\models\User;
use Yii;

class KycController extends ActiveController
{
    public $modelClass = 'common\models\KycRecord';

    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
                'Access-Control-Allow-Headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
            ],
        ];
        return $behaviors;
    }

    protected function verbs()
    {
        return [
            'index' => ['GET', 'POST'],
            'create' => ['POST'],
            'update' => ['PUT', 'PATCH'],
            'delete' => ['DELETE'],
        ];
    }

    public function actionCreate()
    {
        $params = Yii::$app->getRequest()->getBodyParams();
        $userId = Yii::$app->user->id ?? $params['user_id'] ?? null;
        if (!$userId) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'unauthenticated'];
        }
        $record = new KycRecord();
        $record->user_id = $userId;
        $record->entity_type = $params['entity_type'] ?? 'restaurant';
        $record->document_type = $params['document_type'] ?? 'id_card';
        $record->document_number = $params['document_number'] ?? '';
        $record->document_image_url = $params['document_image_url'] ?? '';
        $record->status = 'pending';
        $record->created_at = date('Y-m-d H:i:s');
        if ($record->save()) {
            Yii::$app->db->createCommand()->insert('notifications', [
                'user_id' => null,
                'category' => 'admin',
                'title' => 'New KYC Submission',
                'message' => "User #$userId submitted KYC for {$record->entity_type}",
                'created_at' => date('Y-m-d H:i:s'),
            ])->execute();
            return $record->toArray();
        }
        Yii::$app->response->statusCode = 422;
        return $record->getErrors();
    }

    public function actionUpdate($id)
    {
        $params = Yii::$app->getRequest()->getBodyParams();
        $record = KycRecord::findOne($id);
        if (!$record) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'not_found'];
        }
        if (isset($params['status'])) {
            $record->status = $params['status'];
            if ($params['status'] === 'approved') {
                Yii::$app->db->createCommand()->update('user', ['status' => 'active'], ['id' => $record->user_id])->execute();
                Yii::$app->db->createCommand()->insert('notifications', [
                    'user_id' => $record->user_id,
                    'category' => $record->entity_type === 'restaurant' ? 'restaurant_owner' : 'delivery_agent',
                    'title' => 'Account Verified',
                    'message' => 'Your account has been verified. You can now use all features.',
                    'created_at' => date('Y-m-d H:i:s'),
                ])->execute();
                if ($record->entity_type === 'restaurant') {
                    $user = User::findOne($record->user_id);
                    Yii::$app->db->createCommand()->insert('restaurants', [
                        'owner_id' => $record->user_id,
                        'name' => 'My Restaurant',
                        'description' => 'Restaurant for ' . ($user ? $user->full_name : 'New Owner'),
                        'status' => 'draft',
                        'created_at' => date('Y-m-d H:i:s'),
                    ])->execute();
} elseif ($record->entity_type === 'delivery_agent') {
                     $user = User::findOne($record->user_id);
                     $agencyName = $user ? ($user->full_name . ' Agency') : 'My Agency';
                     Yii::$app->db->createCommand()->insert('delivery_agents', [
                         'user_id' => $record->user_id,
                         'agency_name' => $agencyName,
                         'vehicle_type' => 'bike',
                         'status' => 'active',
                         'created_at' => date('Y-m-d H:i:s'),
                     ])->execute();
                 }
            }
        }
        if (isset($params['admin_remark'])) {
            $record->admin_remark = $params['admin_remark'];
        }
        if ($record->save()) {
            return $record->toArray();
        }
        Yii::$app->response->statusCode = 422;
        return $record->getErrors();
    }
}