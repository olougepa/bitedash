<?php
namespace app\modules\api\controllers;

use Yii;
use yii\rest\Controller;
use yii\web\ServerErrorHttpException;

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
        // Prefer generated OpenAPI if present
        $generated = dirname(__DIR__, 4) . DIRECTORY_SEPARATOR . 'docs' . DIRECTORY_SEPARATOR . 'openapi.generated.json';
        $static = dirname(__DIR__, 4) . DIRECTORY_SEPARATOR . 'docs' . DIRECTORY_SEPARATOR . 'openapi.json';
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
}
