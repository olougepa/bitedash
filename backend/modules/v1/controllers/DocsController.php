<?php
namespace backend\modules\v1\controllers;

use Yii;
use yii\rest\Controller;
use yii\web\ServerErrorHttpException;
use yii\web\ForbiddenHttpException;
use yii\web\Response;

class DocsController extends Controller
{
    // Disable authentication for docs
    public $enableCors = false;

    public function behaviors()
    {
        $behaviors = parent::behaviors();
        // allow unauthenticated access to docs
        unset($behaviors['authenticator']);
        return $behaviors;
    }

    public function actionIndex()
    {
        $generated = dirname(__DIR__, 3) . DIRECTORY_SEPARATOR . 'docs' . DIRECTORY_SEPARATOR . 'openapi.generated.json';
        $static = dirname(__DIR__, 3) . DIRECTORY_SEPARATOR . 'docs' . DIRECTORY_SEPARATOR . 'openapi.json';
        if (file_exists($generated)) {
            $path = $generated;
        } elseif (file_exists($static)) {
            $path = $static;
        } else {
            $path = $generated; // default location for error messaging
        }

        if (!file_exists($path)) {
            throw new ServerErrorHttpException('OpenAPI description not found.');
        }

        $json = @file_get_contents($path);
        if ($json === false) {
            throw new ServerErrorHttpException('Unable to read OpenAPI description.');
        }

        $data = json_decode($json, true);
        if ($data === null) {
            throw new ServerErrorHttpException('OpenAPI JSON invalid.');
        }

        return $data;
    }

    /**
     * Serve Swagger UI HTML. Secured: only when not in production or when ENABLE_SWAGGER=1.
     */
    public function actionUi()
    {
        $env = getenv('YII_ENV') ?: (defined('YII_ENV') ? YII_ENV : null);
        $allow = getenv('ENABLE_SWAGGER');
        if (($env === 'prod' || $env === 'production') && $allow !== '1') {
            throw new ForbiddenHttpException('Swagger UI is disabled in production.');
        }

        $file = dirname(__DIR__, 2) . DIRECTORY_SEPARATOR . 'web' . DIRECTORY_SEPARATOR . 'swagger' . DIRECTORY_SEPARATOR . 'index.html';
        if (!file_exists($file)) {
            throw new ServerErrorHttpException('Swagger UI not found.');
        }

        Yii::$app->response->format = Response::FORMAT_RAW;
        Yii::$app->response->headers->set('Content-Type', 'text/html; charset=UTF-8');
        return file_get_contents($file);
    }
}
