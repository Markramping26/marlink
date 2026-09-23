<?php

$host = '127.0.0.1';
$port = 3306;
$user = 'root';
$pass = '';

echo "Connecting to MySQL server at {$host}:{$port}...\n";

try {
    $pdo = new PDO("mysql:host={$host};port={$port}", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);

    echo "Connected successfully to MySQL.\n";

    $sqlFile = __DIR__ . '/database/marlink_schema.sql';
    if (!file_exists($sqlFile)) {
        die("Error: SQL file not found at {$sqlFile}\n");
    }

    $sql = file_get_contents($sqlFile);
    echo "Importing MarLink schema and seeded data...\n";

    // Split and execute SQL statements
    $pdo->exec($sql);

    echo "SUCCESS: Database `marlink_db` has been created and populated!\n";

    // Verify tables
    $pdo->exec("USE `marlink_db`");
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);

    echo "Tables in `marlink_db` (" . count($tables) . "):\n";
    foreach ($tables as $t) {
        echo " - {$t}\n";
    }

    // Verify users count
    $stmt = $pdo->query("SELECT id, name, email FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "Seeded users:\n";
    foreach ($users as $u) {
        echo " - [ID {$u['id']}] {$u['name']} ({$u['email']})\n";
    }

} catch (PDOException $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
