<?php
namespace backend\modules\v1\controllers;

use yii\rest\Controller;
use yii\web\NotFoundHttpException;
use yii\web\BadRequestHttpException;
use common\models\SystemSetting;
use Yii;

class SettingsController extends Controller
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

    public function actionIndex()
    {
        $settings = SystemSetting::find()->all();
        return $settings;
    }

    public function actionCreate()
    {
        $params = Yii::$app->getRequest()->getBodyParams();
        if (!isset($params['setting_key'])) {
            throw new BadRequestHttpException('setting_key is required');
        }
        $setting = SystemSetting::findOne(['setting_key' => $params['setting_key']]);
        if ($setting) {
            $setting->setting_value = $params['setting_value'];
            $setting->save();
        } else {
            $setting = new SystemSetting();
            $setting->setting_key = $params['setting_key'];
            $setting->setting_value = $params['setting_value'];
            $setting->save();
        }
        // Create notification for admin
        Yii::$app->db->createCommand()->insert('notifications', [
            'user_id' => null,
            'category' => 'admin',
            'title' => 'System Setting Updated',
            'message' => "Setting '{$params['setting_key']}' was updated to '{$params['setting_value']}'",
            'created_at' => date('Y-m-d H:i:s'),
        ])->execute();
        return $setting;
    }

    public function verbs()
    {
        return [
            'index' => ['GET'],
            'create' => ['POST'],
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
}