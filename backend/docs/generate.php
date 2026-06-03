<?php
// Simple generator: copy static openapi.json to openapi.generated.json
// This avoids runtime reflection issues while keeping a reproducible spec.
$static = __DIR__ . '/openapi.json';
$out = __DIR__ . '/openapi.generated.json';
if (file_exists($static)) {
    copy($static, $out);
    echo "Copied $static to $out\n";
} else {
    // Fallback to swagger-php if available
    if (file_exists(__DIR__ . '/../vendor/autoload.php')) {
        require __DIR__ . '/../vendor/autoload.php';
        try {
            $openapi = \OpenApi\Generator::scan([__DIR__ . '/../src', __DIR__]);
            file_put_contents($out, $openapi->toJson());
            echo "Wrote $out via swagger-php\n";
        } catch (\Throwable $e) {
            echo "Failed to generate OpenAPI: " . $e->getMessage() . "\n";
            exit(1);
        }
    } else {
        echo "No source and no vendor available to generate OpenAPI.\n";
        exit(1);
    }
}
