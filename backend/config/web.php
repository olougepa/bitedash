<?php
return [
    'id' => 'bitedash-api',
    'basePath' => dirname(__DIR__),
    'bootstrap' => ['log'],
    'components' => [
        'request' => [
            'parsers' => [
                'application/json' => 'yii\web\JsonParser',
            ],
        ],
        'user' => [
            'identityClass' => 'app\\models\\User',
            'enableAutoLogin' => false,
            'enableSession' => false,
        ],
        'response' => [
            'format' => yii\web\Response::FORMAT_JSON,
            'charset' => 'UTF-8',
        ],
        'urlManager' => [
            'enablePrettyUrl' => true,
            'enableStrictParsing' => true,
            'showScriptName' => false,
            'rules' => [
                // Explicit auth endpoints (handle login/register/refresh/profile)
                'OPTIONS api/auth/login' => 'api/auth/login',
                'POST api/auth/login' => 'api/auth/login',
                'POST api/auth/register' => 'api/auth/register',
                'GET api/openapi.json' => 'api/docs/index',
                'GET api/openapi' => 'api/docs/index',
                'POST api/auth/refresh' => 'api/auth/refresh',
                'GET api/auth/profile' => 'api/auth/profile',
                ['class' => 'yii\\rest\\UrlRule', 'controller' => ['api/restaurant', 'api/order', 'api/user', 'api/delivery-agent', 'api/payment', 'api/notification', 'api/menu-item', 'api/auth']],
            ],
        ],
        'db' => require __DIR__ . '/db.php',
        'log' => [
            'targets' => [
                [
                    'class' => 'yii\log\FileTarget',
                    'levels' => ['error', 'warning'],
                ],
            ],
        ],
    ],
    'modules' => [
        'api' => [
            'class' => 'app\modules\api\Module',
        ],
    ],
];
