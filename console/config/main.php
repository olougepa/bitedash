<?php
return [
    'id' => 'bitedash-console',
    'basePath' => dirname(dirname(__DIR__)),
    'bootstrap' => ['log'],
    'controllerNamespace' => 'console\\controllers',
    'components' => [
        'db' => require dirname(dirname(__DIR__)) . '/common/config/db.php',
    ],
];