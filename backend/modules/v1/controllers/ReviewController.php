<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use Yii;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use common\models\Rating;
use common\models\User;
use common\models\Restaurant;
use common\models\DeliveryAgent;
use common\models\Order;

class ReviewController extends ActiveController
{
    public $modelClass = 'common\models\Rating';

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

    public function actions()
    {
        $actions = parent::actions();
        unset($actions['create']);
        return $actions;
    }

    protected function getBodyParams()
    {
        $req = Yii::$app->request;
        $contentType = $req->getHeaders()->get('Content-Type');
        if ($contentType && stripos($contentType, 'application/json') !== false) {
            $rawBody = file_get_contents('php://input');
            return json_decode($rawBody, true) ?: [];
        }
        return $req->bodyParams;
    }

    public function actionCreate()
    {
        $currentUser = $this->getCurrentUser();
        if (!$currentUser) {
            throw new \yii\web\UnauthorizedHttpException('Authentication required');
        }

        $body = $this->getBodyParams();
        $targetType = $body['target_type'] ?? null;
        $targetId = $body['target_id'] ?? null;
        $rating = $body['rating'] ?? null;
        $comment = $body['comment'] ?? '';

        if (!$targetType || !$targetId || !$rating) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'missing_fields'];
        }

        $ratingModel = new Rating();
        $ratingModel->reviewer_id = $currentUser->id;
        $ratingModel->target_type = $targetType;
        $ratingModel->target_id = $targetId;
        $ratingModel->rating = $rating;
        $ratingModel->comment = $comment;

        if ($ratingModel->save()) {
            return ['status' => 'created', 'data' => $ratingModel->toArray()];
        }

        Yii::$app->response->statusCode = 422;
        return $ratingModel->getErrors();
    }

    public function actionIndex()
    {
        $targetType = Yii::$app->request->get('target_type');
        $targetId = Yii::$app->request->get('target_id');

        $query = Rating::find();
        if ($targetType) {
            $query->andWhere(['target_type' => $targetType]);
        }
        if ($targetId) {
            $query->andWhere(['target_id' => $targetId]);
        }

        return $query->all();
    }

    protected function getCurrentUser()
    {
        $request = Yii::$app->request;
        $authHeader = $request->getHeaders()->get('Authorization');
        if (!$authHeader || !preg_match('/Bearer\s+(.*)/', $authHeader, $matches)) {
            return null;
        }
        $token = $matches[1];
        $secret = getenv('JWT_SECRET') ?: (Yii::$app->params['jwtSecret'] ?? 'bitedash_secret_change_me');
        try {
            $decoded = JWT::decode($token, new Key($secret, 'HS256'));
        } catch (\Exception $e) {
            return null;
        }
        if (empty($decoded->sub)) return null;
        return User::findOne($decoded->sub);
    }
}