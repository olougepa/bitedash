<?php
namespace backend\modules\v1\controllers;

use Yii;
use yii\rest\Controller;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use common\models\User;

class AuthController extends Controller
{
    public $enableCsrfValidation = false;

    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['corsFilter'] = [
            'class' => \yii\filters\Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['POST', 'GET', 'OPTIONS'],
                'Access-Control-Allow-Headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
            ],
        ];
        return $behaviors;
    }

    protected function getBodyParam($name, $default = null)
    {
        $req = Yii::$app->request;
        $contentType = $req->getHeaders()->get('Content-Type');
        if ($contentType && stripos($contentType, 'application/json') !== false) {
            $rawBody = file_get_contents('php://input');
            $body = json_decode($rawBody, true) ?: [];
            return $body[$name] ?? $default;
        }
        return $req->post($name, $default);
    }

    public function actionLogin()
    {
        $email = $this->getBodyParam('email');
        $phone = $this->getBodyParam('phone');
        $password = $this->getBodyParam('password');
        $identifier = $email ?: $phone;
        
        if (!$identifier || !$password) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'missing_credentials'];
        }
        
        $user = null;
        if ($email) {
            $user = User::findOne(['email' => $email]);
        }
        if (!$user && $phone) {
            $user = User::findOne(['phone' => $phone]);
        }
        
        if (!$user) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'invalid_credentials'];
        }
        
        $secret = getenv('JWT_SECRET') ?: (Yii::$app->params['jwtSecret'] ?? 'bitedash_secret_change_me');
        $passwordOk = false;
        if (password_verify($password, $user->password_hash)) {
            $passwordOk = true;
        } elseif ($user->password_hash === $password) {
            $user->password_hash = password_hash($password, PASSWORD_DEFAULT);
            $user->save(false);
            $passwordOk = true;
        }
        if (!$passwordOk) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'invalid_credentials'];
        }

        $now = time();
        $accessExp = $now + 900;
        $payload = [
            'sub' => $user->id,
            'iat' => $now,
            'exp' => $accessExp,
        ];
        $accessToken = JWT::encode($payload, $secret, 'HS256');

        $refreshToken = bin2hex(random_bytes(32));
        $expiresAt = date('Y-m-d H:i:s', strtotime('+30 days'));
        Yii::$app->db->createCommand()->insert('refresh_tokens', [
            'user_id' => $user->id,
            'token' => $refreshToken,
            'expires_at' => $expiresAt,
            'created_at' => date('Y-m-d H:i:s'),
        ])->execute();

        return [
            'access_token' => $accessToken,
            'token_type' => 'Bearer',
            'expires_in' => 900,
            'refresh_token' => $refreshToken,
            'user' => $user->toArray(),
        ];
    }

    public function actionRegister()
    {
        $phone = $this->getBodyParam('phone');
        $email = $this->getBodyParam('email') ?? ($phone ? "$phone@bitedash.temp" : null);
        $password = $this->getBodyParam('password');
        $name = $this->getBodyParam('name', $phone ?? $email);
        $role = $this->getBodyParam('role', 'customer');
        if (!$phone && !$email) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'missing_fields'];
        }
        $existing = User::findOne(['email' => $email]);
        if (!$existing && $phone) {
            $existing = User::findOne(['phone' => $phone]);
        }
        if ($existing) {
            Yii::$app->response->statusCode = 409;
            return ['error' => 'already_exists'];
        }
        $user = new User();
        $user->email = $email;
        $user->phone = $phone;
        $user->password_hash = password_hash($password, PASSWORD_DEFAULT);
        $user->full_name = $name;
        $user->role = in_array($role, ['restaurant_owner', 'delivery_agent']) ? $role : 'customer';
        $user->status = 'active';
        if (!$user->save()) {
            Yii::$app->response->statusCode = 500;
            return ['error' => 'save_failed', 'details' => $user->errors];
        }
        if ($role === 'restaurant_owner') {
            $user->status = 'pending';
            $user->save(false);
        }
        if ($role === 'delivery_agent') {
            $user->status = 'pending';
            $user->save(false);
        }
        if ($role === 'restaurant_owner' || $role === 'delivery_agent') {
            $docType = $this->getBodyParam('document_type', 'id_card');
            $docNumber = $this->getBodyParam('document_number', '');
            $docImage = $this->getBodyParam('document_image_url', '');
            Yii::$app->db->createCommand()->insert('kyc_records', [
                'user_id' => $user->id,
                'entity_type' => $role === 'restaurant_owner' ? 'restaurant' : 'delivery_agent',
                'document_type' => $docType,
                'document_number' => $docNumber,
                'document_image_url' => $docImage,
                'status' => 'pending',
                'created_at' => date('Y-m-d H:i:s'),
            ])->execute();
        }
        $secret = getenv('JWT_SECRET') ?: (Yii::$app->params['jwtSecret'] ?? 'bitedash_secret_change_me');
        $now = time();
        $accessExp = $now + 900;
        $payload = ['sub' => $user->id, 'iat' => $now, 'exp' => $accessExp];
        $accessToken = JWT::encode($payload, $secret, 'HS256');
        $refreshToken = bin2hex(random_bytes(32));
        Yii::$app->db->createCommand()->insert('refresh_tokens', [
            'user_id' => $user->id,
            'token' => $refreshToken,
            'expires_at' => date('Y-m-d H:i:s', strtotime('+30 days')),
            'created_at' => date('Y-m-d H:i:s'),
        ])->execute();
        $user->refresh();
        return [
            'access_token' => $accessToken,
            'token_type' => 'Bearer',
            'expires_in' => 900,
            'refresh_token' => $refreshToken,
            'user' => $user->toArray(),
        ];
    }

    public function actionProfile()
    {
        $req = Yii::$app->request;
        $auth = $req->getHeaders()->get('Authorization');
        if (!$auth || !preg_match('/Bearer\s+(.*)/', $auth, $m)) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'missing_token'];
        }
        $token = $m[1];
        $secret = getenv('JWT_SECRET') ?: (Yii::$app->params['jwtSecret'] ?? 'bitedash_secret_change_me');
        try {
            $decoded = JWT::decode($token, new Key($secret, 'HS256'));
        } catch (\Exception $e) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'invalid_token', 'message' => $e->getMessage()];
        }
        $userId = $decoded->sub ?? null;
        if (!$userId) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'invalid_token_claims'];
        }
        $user = User::findOne($userId);
        if (!$user) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'user_not_found'];
        }
        return $user->toArray();
    }

    public function actionRefresh()
    {
        $rt = $this->getBodyParam('refresh_token');
        if (!$rt) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'missing_refresh_token'];
        }
        $row = Yii::$app->db->createCommand('SELECT * FROM refresh_tokens WHERE token=:t AND expires_at>NOW()')
            ->bindValue(':t', $rt)
            ->queryOne();
        if (!$row) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'invalid_refresh_token'];
        }
        $user = User::findOne($row['user_id']);
        if (!$user) {
            Yii::$app->response->statusCode = 404;
            return ['error' => 'user_not_found'];
        }
        $secret = getenv('JWT_SECRET') ?: (Yii::$app->params['jwtSecret'] ?? 'bitedash_secret_change_me');
        $now = time();
        $accessExp = $now + 900;
        $payload = ['sub' => $user->id, 'iat' => $now, 'exp' => $accessExp];
        $accessToken = JWT::encode($payload, $secret, 'HS256');

        $newRefresh = bin2hex(random_bytes(32));
        Yii::$app->db->createCommand()->update('refresh_tokens', ['token' => $newRefresh, 'created_at' => date('Y-m-d H:i:s')], ['id' => $row['id']])->execute();

        return [
            'access_token' => $accessToken,
            'token_type' => 'Bearer',
            'expires_in' => 900,
            'refresh_token' => $newRefresh,
        ];
    }
}