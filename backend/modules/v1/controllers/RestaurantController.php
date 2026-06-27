<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use common\models\Restaurant;
use common\models\User;
use Yii;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class RestaurantController extends ActiveController
{
    public $modelClass = 'common\models\Restaurant';

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
            'index' => ['GET'],
            'create' => ['POST'],
            'update' => ['PUT', 'PATCH'],
            'delete' => ['DELETE'],
        ];
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

    public function actionIndex()
    {
        $currentUser = $this->getCurrentUser();
        $query = Restaurant::find();

        if ($currentUser && $currentUser->role === 'restaurant_owner') {
            $existingRestaurant = Restaurant::find()->where(['owner_id' => $currentUser->id])->one();
            if (!$existingRestaurant) {
                $existingRestaurant = new Restaurant();
                $existingRestaurant->owner_id = $currentUser->id;
                $existingRestaurant->name = 'My Restaurant';
                $existingRestaurant->status = 'draft';
                $existingRestaurant->save(false);
            }
            $query->andWhere(['owner_id' => $currentUser->id]);
        }

        $status = Yii::$app->request->get('status');
        if ($status) {
            $query->andWhere(['status' => $status]);
        }

        $cityId = Yii::$app->request->get('city_id');
        if ($cityId) {
            $query->andWhere(['city_id' => $cityId]);
        }

        return $query->all();
    }

    public function actionCreate()
    {
        $currentUser = $this->getCurrentUser();
        $params = $this->getBodyParams();

        $restaurant = new Restaurant();
        $restaurant->load($params, '');
        
        if ($currentUser && $currentUser->role === 'restaurant_owner') {
            $restaurant->owner_id = $currentUser->id;
        }

        if ($restaurant->save()) {
            return $restaurant;
        }

        Yii::$app->response->statusCode = 422;
        return $restaurant->getErrors();
    }

    public function actionUpdate($id)
    {
        $currentUser = $this->getCurrentUser();
        $restaurant = Restaurant::findOne($id);

        if (!$restaurant) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'Restaurant not found'];
        }

        if ($currentUser && $currentUser->role === 'restaurant_owner' && $restaurant->owner_id !== $currentUser->id) {
            Yii::$app->response->statusCode = 403;
            return ['error' => 'Not authorized'];
        }

        $params = $this->getBodyParams();
        $restaurant->load($params, '');

        if ($restaurant->save()) {
            return $restaurant;
        }

        Yii::$app->response->statusCode = 422;
        return $restaurant->getErrors();
    }
}