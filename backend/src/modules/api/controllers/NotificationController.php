<?php
namespace app\modules\api\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use Yii;
use app\models\Notification;

/**
 * NotificationController
 */
class NotificationController extends ActiveController
{
    public $modelClass = 'app\\models\\Notification';

    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
                'Access-Control-Allow-Credentials' => true,
            ],
        ];
        return $behaviors;
    }

    public function actions()
    {
        return parent::actions();
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
