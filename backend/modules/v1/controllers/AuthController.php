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
        // allow CORS for simplicity
        $behaviors['corsFilter'] = [
            'class' => \yii\filters\Cors::class,
            'cors' => [
                'Origin' => ['*'],
                'Access-Control-Request-Method' => ['POST', 'GET', 'OPTIONS'],
            ],
        ];
        return $behaviors;
    }

    /**
     * @OA\Post(
     *   path="/auth/login",
     *   summary="Login",
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\MediaType(
     *       mediaType="application/json",
     *       @OA\Schema(ref="#/components/schemas/LoginRequest")
     *     )
     *   ),
     *   @OA\Response(response=200, description="OK", @OA\MediaType(mediaType="application/json", @OA\Schema(ref="#/components/schemas/AuthResponse"))),
     *   @OA\Response(response=401, description="Invalid credentials")
     * )
     */
    public function actionLogin()
    {
        $req = Yii::$app->request;
        $email = $req->post('email');
        $password = $req->post('password');
        if (!$email || !$password) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'missing_credentials'];
        }
        $user = User::findOne(['email' => $email]);
        if (!$user) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'invalid_credentials'];
        }
        $secret = getenv('JWT_SECRET') ?: (Yii::$app->params['jwtSecret'] ?? 'bitedash_secret_change_me');
        // support legacy plain-text passwords: if stored value equals provided, upgrade to hashed
        $passwordOk = false;
        if (password_verify($password, $user->password_hash)) {
            $passwordOk = true;
        } elseif ($user->password_hash === $password) {
            // legacy: hash and save
            $user->password_hash = password_hash($password, PASSWORD_DEFAULT);
            $user->save(false);
            $passwordOk = true;
        }
        if (!$passwordOk) {
            Yii::$app->response->statusCode = 401;
            return ['error' => 'invalid_credentials'];
        }

        $now = time();
        $accessExp = $now + 900; // 15 minutes
        $payload = [
            'sub' => $user->id,
            'iat' => $now,
            'exp' => $accessExp,
        ];
        $accessToken = JWT::encode($payload, $secret, 'HS256');

        // create refresh token
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

    /**
     * @OA\Post(
     *   path="/auth/register",
     *   summary="Register user",
     *   @OA\RequestBody(required=true, @OA\MediaType(mediaType="application/json")),
     *   @OA\Response(response=201, description="Created")
     * )
     */
    public function actionRegister()
    {
        $req = Yii::$app->request;
        $email = $req->post('email');
        $password = $req->post('password');
        $name = $req->post('name') ?: $email;
        if (!$email || !$password) {
            Yii::$app->response->statusCode = 400;
            return ['error' => 'missing_fields'];
        }
        if (User::find()->where(['email' => $email])->exists()) {
            Yii::$app->response->statusCode = 409;
            return ['error' => 'already_exists'];
        }
        $user = new User();
        $user->email = $email;
        $user->password_hash = password_hash($password, PASSWORD_DEFAULT);
        $user->full_name = $name;
        $user->role = 'customer';
        $user->status = 'active';
        if (!$user->save()) {
            Yii::$app->response->statusCode = 500;
            return ['error' => 'save_failed', 'details' => $user->errors];
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
        return [
            'access_token' => $accessToken,
            'token_type' => 'Bearer',
            'expires_in' => 900,
            'refresh_token' => $refreshToken,
            'user' => $user->toArray(),
        ];
    }

    /**
     * @OA\Get(
     *   path="/auth/profile",
     *   summary="Get profile",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="User", @OA\MediaType(mediaType="application/json"))
     * )
     */
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
        $req = Yii::$app->request;
        $rt = $req->post('refresh_token');
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

        // rotate refresh token
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
