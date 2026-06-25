<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use common\models\Restaurant;
use Yii;

/**
 * @OA\Tag(name="Restaurant", description="Operations related to restaurants")
 */
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

    public function actionIndex()
    {
        $currentUser = Yii::$app->user->identity;
        $query = Restaurant::find();

        if ($currentUser && $currentUser->role === 'restaurant_owner') {
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
}