<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use common\models\MenuItem;
use common\models\Restaurant;
use Yii;

class MenuItemController extends ActiveController
{
    public $modelClass = 'common\models\MenuItem';

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

    public function actionIndex()
    {
        $currentUser = Yii::$app->user->identity;
        $query = MenuItem::find();

        if ($currentUser && $currentUser->role === 'restaurant_owner') {
            $ownedRestaurantIds = Restaurant::find()
                ->select('id')
                ->where(['owner_id' => $currentUser->id])
                ->column();
            if (!empty($ownedRestaurantIds)) {
                $query->andWhere(['restaurant_id' => $ownedRestaurantIds]);
            } else {
                $query->andWhere(['restaurant_id' => -1]);
            }
        }

        $restaurantId = Yii::$app->request->get('restaurant_id');
        if ($restaurantId) {
            $query->andWhere(['restaurant_id' => $restaurantId]);
        }

        $cityId = Yii::$app->request->get('city_id');
        if ($cityId) {
            $query->andWhere(['city_id' => $cityId]);
        }

        return $query->all();
    }

    public function actionCreate()
    {
        $currentUser = Yii::$app->user->identity;
        $params = Yii::$app->getRequest()->getBodyParams();

        $menuItem = new MenuItem();
        $menuItem->load($params, '');

        if ($currentUser && $currentUser->role === 'restaurant_owner') {
            $ownedRestaurant = Restaurant::find()
                ->where(['owner_id' => $currentUser->id])
                ->one();
            if ($ownedRestaurant) {
                $menuItem->restaurant_id = $ownedRestaurant->id;
            }
        }

        if ($menuItem->save()) {
            return $menuItem;
        }

        Yii::$app->response->statusCode = 422;
        return $menuItem->getErrors();
    }
}