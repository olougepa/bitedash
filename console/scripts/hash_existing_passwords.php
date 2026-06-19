<?php
// Usage: php hash_existing_passwords.php
// This script will read users where password_hashed=0 and replace the stored password
// with a secure hash using password_hash(), then mark password_hashed=1.

require __DIR__ . '/../../vendor/autoload.php';

// Adjust these requires to match your Yii2 bootstrap if needed.

$yii = __DIR__ . '/../../../vendor/yiisoft/yii2/Yii.php';
if (!file_exists($yii)) {
    echo "Yii framework not found via vendor; make sure to run composer install first.\n";
    exit(1);
}

// Minimal DB access using PDO to avoid bootstrapping whole app
$config = [
    'dsn' => 'mysql:host=127.0.0.1;dbname=bitedash;charset=utf8mb4',
    'user' => 'root',
    'pass' => '',
];

$pdo = new PDO($config['dsn'], $config['user'], $config['pass'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

$stmt = $pdo->query("SELECT id, password_hash FROM users WHERE password_hashed=0");
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
if (!$rows) {
    echo "No legacy passwords found (password_hashed=0).\n";
    exit(0);
}

foreach ($rows as $r) {
    $id = $r['id'];
    $plain = $r['password_hash'];
    if (empty($plain)) {
        echo "User $id has empty password, skipping.\n";
        continue;
    }
    $newHash = password_hash($plain, PASSWORD_DEFAULT);
    $up = $pdo->prepare("UPDATE users SET password_hash=:h, password_hashed=1 WHERE id=:id");
    $up->execute([':h' => $newHash, ':id' => $id]);
    echo "User $id password hashed.\n";
}

echo "Done. Review and remove this script after successful run.\n";
