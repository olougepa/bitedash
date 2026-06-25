<?php
namespace backend\modules\v1\controllers;

use Yii;
use yii\rest\ActiveController;
use yii\filters\Cors;
use common\models\Ad;

class AdController extends ActiveController
{
    public $modelClass = 'common\models\Ad';

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
            'view' => ['GET'],
            'create' => ['POST'],
            'update' => ['PUT', 'PATCH'],
            'delete' => ['DELETE'],
            'approve' => ['PATCH'],
            'reject' => ['PATCH'],
        ];
    }

    public function actionIndex()
    {
        $user = Yii::$app->user->identity;
        $query = Ad::find();

        $requestStatus = Yii::$app->request->get('status');
        $now = date('Y-m-d H:i:s');

        if ($user) {
            $role = $user->role;
            if ($role === 'admin') {
                // Admin sees all ads
            } elseif ($role === 'restaurant_owner') {
                $query->andWhere(['owner_id' => $user->id]);
            } elseif ($role === 'delivery_agent') {
                $agent = \common\models\DeliveryAgent::findOne(['user_id' => $user->id]);
                if ($agent) {
                    $query->andWhere(['agent_id' => $agent->id]);
                } else {
                    $query->andWhere(['agent_id' => null]);
                }
            }
        } else {
            // For public (non-authenticated users), only show approved and not expired ads
            $query->andWhere(['status' => 'approved']);
            $query->andWhere(['or', ['>', 'end_date', $now], ['end_date' => null]]);
        }

        // Apply status filter from query (for AdsBanner which passes status=approved)
        if ($requestStatus) {
            $query->andWhere(['status' => $requestStatus]);
        }

        // Filter out expired ads
        $query->andWhere(['or', ['>', 'end_date', $now], ['end_date' => null]]);

        return $query->all();
    }

    public function actionCreate()
    {
        $user = Yii::$app->user->identity;
        $params = Yii::$app->getRequest()->getBodyParams();
        
        $ad = new Ad();

        // Assign owner_id or agent_id BEFORE load
        if ($user) {
            $role = $user->role;
            if ($role === 'restaurant_owner') {
                $ad->owner_id = $user->id;
            } elseif ($role === 'delivery_agent') {
                $agent = \common\models\DeliveryAgent::findOne(['user_id' => $user->id]);
                $ad->agent_id = $agent ? $agent->id : null;
            }
        } elseif (isset($params['owner_id'])) {
            $ad->owner_id = $params['owner_id'];
        } elseif (isset($params['agent_id'])) {
            $ad->agent_id = $params['agent_id'];
        }

        $ad->title = $params['title'] ?? '';
        $ad->description = $params['description'] ?? '';
        $ad->image_url = $params['image_url'] ?? null;
        $ad->target_type = $params['target_type'] ?? 'restaurant';
        $ad->budget = $params['budget'] ?? null;
        $ad->status = $params['status'] ?? 'pending';
        $ad->start_date = $params['start_date'] ?? date('Y-m-d H:i:s');
        $ad->end_date = $params['end_date'] ?? null;

        // Calculate duration_days from start_date and end_date if provided
        if ($ad->start_date && $ad->end_date) {
            $start = new \DateTime($ad->start_date);
            $end = new \DateTime($ad->end_date);
            $ad->duration_days = $start->diff($end)->days + 1;
        } else {
            $ad->duration_days = $params['duration_days'] ?? 7;
            if (!$ad->end_date) {
                $ad->end_date = date('Y-m-d H:i:s', strtotime("+{$ad->duration_days} days"));
            }
        }

        if ($ad->save()) {
            return $ad->toArray();
        }

        Yii::$app->response->statusCode = 422;
        return $ad->getErrors();
    }

    public function actionUpdate($id)
    {
        $ad = Ad::findOne($id);
        if (!$ad) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'not_found'];
        }

        $params = Yii::$app->getRequest()->getBodyParams();
        
        $ad->title = $params['title'] ?? $ad->title;
        $ad->description = $params['description'] ?? $ad->description;
        $ad->image_url = $params['image_url'] ?? $ad->image_url;
        $ad->target_type = $params['target_type'] ?? $ad->target_type;
        $ad->budget = $params['budget'] ?? $ad->budget;
        $ad->status = $params['status'] ?? $ad->status;
        
        if (isset($params['owner_id'])) {
            $ad->owner_id = $params['owner_id'];
        }
        if (isset($params['agent_id'])) {
            $ad->agent_id = $params['agent_id'];
        }
        
        if (isset($params['start_date'])) {
            $ad->start_date = $params['start_date'];
        }
        if (isset($params['end_date'])) {
            $ad->end_date = $params['end_date'];
        }
        
        // Recalculate duration_days if both dates provided
        if ($ad->start_date && $ad->end_date) {
            $start = new \DateTime($ad->start_date);
            $end = new \DateTime($ad->end_date);
            $ad->duration_days = $start->diff($end)->days + 1;
        }

        if ($ad->save()) {
            return $ad->toArray();
        }

        Yii::$app->response->statusCode = 422;
        return $ad->getErrors();
    }

    public function actionApprove($id)
    {
        $ad = Ad::findOne($id);
        if (!$ad) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'not_found'];
        }
        $ad->status = 'approved';
        if ($ad->save()) {
            return $ad->toArray();
        }
        Yii::$app->response->statusCode = 422;
        return $ad->getErrors();
    }

    public function actionReject($id)
    {
        $params = Yii::$app->getRequest()->getBodyParams();
        $ad = Ad::findOne($id);
        if (!$ad) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'not_found'];
        }
        $ad->status = 'rejected';
        $ad->admin_remark = $params['admin_remark'] ?? null;
        if ($ad->save()) {
            return $ad->toArray();
        }
        Yii::$app->response->statusCode = 422;
        return $ad->getErrors();
    }
}