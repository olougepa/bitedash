<?php
namespace backend\controllers;

use yii\web\Controller;

class SiteController extends Controller
{
    public function actionIndex()
    {
        return ['message' => 'Bitedash API v1', 'version' => '1.0'];
    }
}