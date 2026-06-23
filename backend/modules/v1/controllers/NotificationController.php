<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use Yii;
use common\models\Notification;

/**
 * NotificationController
 */
class NotificationController extends ActiveController
{
    public $modelClass = 'common\models\Notification';

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
        return parent::actions();
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
        $request = Yii::$app->request;
        $query = Notification::find();
        $userId = $request->get('user_id');
        $category = $request->get('category');
        if ($userId) {
            $query->andWhere(['user_id' => $userId]);
        }
        if ($category) {
            $query->andWhere(['or', ['category' => $category], ['category' => 'all']]);
        }
        return $query->orderBy(['created_at' => SORT_DESC])->all();
    }
}
