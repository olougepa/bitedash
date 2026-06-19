<?php
// Attempt full swagger-php generation first (controllers + models + docs)
$out = __DIR__ . '/openapi.generated.json';
$static = __DIR__ . '/openapi.json';
if (file_exists(__DIR__ . '/../vendor/autoload.php')) {
    require __DIR__ . '/../vendor/autoload.php';
    try {
        // scan controllers and models for annotations
        $scan = [
            realpath(__DIR__ . '/../controllers/api'),
            realpath(__DIR__ . '/../../common/models'),
            realpath(__DIR__),
        ];
        $scan = array_filter($scan);
        $openapi = \OpenApi\Generator::scan($scan);
        $json = $openapi->toJson();
        // if generation produced non-empty paths, accept it; otherwise fallback to static
        $decoded = json_decode($json, true);
        if (is_array($decoded) && !empty($decoded['paths'])) {
            file_put_contents($out, $json);
            echo "Wrote $out via swagger-php\n";
            exit(0);
        }
        echo "swagger-php produced no paths, falling back to static spec\n";
    } catch (\Throwable $e) {
        echo "swagger-php generation failed: " . $e->getMessage() . "\n";
    }
}

// fallback: copy static openapi.json so a full spec is always available
if (file_exists($static)) {
    copy($static, $out);
    echo "Copied $static to $out\n";
} else {
    echo "No static openapi.json found to copy.\n";
    exit(1);
}
