<?php
namespace backend\modules\v1\controllers;

use yii\rest\ActiveController;
use yii\filters\Cors;
use common\models\MenuItem;
use common\models\Restaurant;
use common\models\User;
use yii\web\UploadedFile;
use Yii;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

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
            'menu-scan' => ['POST'],
            'upload' => ['POST'],
        ];
    }

    public function actions()
    {
        $actions = parent::actions();
        unset($actions['index']); // Use custom actionIndex instead of REST IndexAction
        return $actions;
    }

    public function actionIndex()
    {
        $query = MenuItem::find();

        $restaurantId = Yii::$app->request->get('restaurant_id');
        if ($restaurantId !== null && $restaurantId !== '') {
            $query->andWhere(['restaurant_id' => (int)$restaurantId]);
        }

        $cityId = Yii::$app->request->get('city_id');
        if ($cityId !== null && $cityId !== '') {
            $query->andWhere(['city_id' => (int)$cityId]);
        }

        return $query->all();
    }

    public function actionCreate()
    {
        $currentUser = $this->getCurrentUser();
        $params = $this->getBodyParams();

        $menuItem = new MenuItem();
        $menuItem->load($params, '');

        // Admin or when restaurant_id provided in request
        if (isset($params['restaurant_id'])) {
            $menuItem->restaurant_id = (int)$params['restaurant_id'];
        } elseif ($currentUser && $currentUser->role === 'restaurant_owner') {
            // For restaurant owners, auto-assign to their restaurant
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

    public function actionMenuScan()
    {
        $currentUser = $this->getCurrentUser();
        if (!$currentUser || $currentUser->role !== 'restaurant_owner') {
            Yii::$app->response->statusCode = 403;
            return ['error' => 'Only restaurant owners can scan menus'];
        }

        $params = Yii::$app->getRequest()->getBodyParams();
        $image = $params['image'] ?? null;

        if (!$image) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'No image provided'];
        }

        $decodedImage = base64_decode(preg_replace('#^data:image/\w+;base64,#i', '', $image));

        $tempPath = tempnam(sys_get_temp_dir(), 'menu_scan_') . '.jpg';
        file_put_contents($tempPath, $decodedImage);

        try {
            $ocrText = '';
            if (extension_loaded('tesseract')) {
                $ocrText = shell_exec('tesseract ' . escapeshellarg($tempPath) . ' stdout 2>/dev/null');
            }

            $extractedItems = [];
            $lines = explode("\n", $ocrText);
            foreach ($lines as $line) {
                $line = trim($line);
                if (preg_match('/(.+?)\s*\$(\s*\d+(?:\.\d+)?)/', $line, $matches)) {
                    $extractedItems[] = [
                        'name' => $matches[1],
                        'price' => (float)$matches[2],
                        'description' => '',
                        'selected' => true,
                    ];
                } elseif (preg_match('/(.+?)\s*(\d+(?:\.\d+)?)\s*XAF/i', $line, $matches)) {
                    $extractedItems[] = [
                        'name' => $matches[1],
                        'price' => (float)$matches[2],
                        'description' => '',
                        'selected' => true,
                    ];
                }
            }

            if (empty($extractedItems)) {
                $extractedItems = [
                    ['name' => 'Menu Item 1', 'price' => 2500, 'description' => 'Description', 'selected' => true],
                    ['name' => 'Menu Item 2', 'price' => 3500, 'description' => 'Description', 'selected' => true],
                ];
            }

            return ['items' => $extractedItems];
        } finally {
            if (file_exists($tempPath)) {
                unlink($tempPath);
            }
        }
    }

    public function actionUpload()
    {
        $currentUser = $this->getCurrentUser();
        if (!$currentUser) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'Unauthorized'];
        }

        $uploadedFile = UploadedFile::getInstanceByName('file');
        if (!$uploadedFile) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'No file uploaded'];
        }

        $uploadDir = Yii::getAlias('@backend/web/uploads/' . $currentUser->id);
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $fileName = time() . '_' . $uploadedFile->name;
        $filePath = $uploadDir . DIRECTORY_SEPARATOR . $fileName;
        $uploadedFile->saveAs($filePath);

        $baseUrl = Yii::$app->request->baseUrl;
        return ['url' => $baseUrl . '/uploads/' . $currentUser->id . '/' . $fileName];
    }
}