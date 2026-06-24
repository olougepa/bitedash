<?php
namespace backend\modules\v1\controllers;

use yii\rest\Controller;
use Yii;

class PriceRequestController extends Controller
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => \yii\filters\Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
                'Access-Control-Allow-Headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
            ],
        ];
        return $behaviors;
    }

    public function actionCreate()
    {
        $params = Yii::$app->getRequest()->getBodyParams();
        $deliveryAgentId = $params['delivery_agent_id'] ?? null;
        $proposedPrice = $params['proposed_price'] ?? null;
        if (!$deliveryAgentId || !$proposedPrice) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'delivery_agent_id and proposed_price required'];
        }
        Yii::$app->db->createCommand()->insert('price_requests', [
            'delivery_agent_id' => $deliveryAgentId,
            'proposed_price' => $proposedPrice,
            'status' => 'pending',
            'created_at' => date('Y-m-d H:i:s'),
        ])->execute();
        return ['success' => true];
    }

    public function actionIndex()
    {
        $requests = Yii::$app->db->createCommand('SELECT * FROM price_requests ORDER BY created_at DESC')->queryAll();
        return $requests;
    }

    public function actionUpdate($id)
    {
        $params = Yii::$app->getRequest()->getBodyParams();
        $status = $params['status'] ?? null;
        $adminRemark = $params['admin_remark'] ?? '';
        if (!in_array($status, ['pending', 'approved', 'rejected'])) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'invalid status'];
        }
        $request = Yii::$app->db->createCommand('SELECT * FROM price_requests WHERE id = :id')->bindValue(':id', $id)->queryOne();
        if (!$request) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'request not found'];
        }
        Yii::$app->db->createCommand()->update('price_requests', [
            'status' => $status,
            'admin_remark' => $adminRemark,
            'updated_at' => date('Y-m-d H:i:s'),
        ], ['id' => $id])->execute();
        if ($status === 'approved') {
            Yii::$app->db->createCommand()->update('delivery_agents', [
                'price_per_km' => $request['proposed_price'],
            ], ['id' => $request['delivery_agent_id']])->execute();
        }
        return ['success' => true];
    }
}