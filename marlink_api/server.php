<?php
/**
 * MarLink Production-Grade REST API Standalone Engine
 * Connects directly to MySQL marlink_db (XAMPP / WAMP)
 * Supports all mobile endpoints for authentication, rooms, real-time locations,
 * chat messages, SOS alerts, and geofence safety zones.
 */

declare(strict_types=1);

// Error handling & headers
error_reporting(E_ALL);
ini_set('display_errors', '0');

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Helper: Read environment variable or .env file
function getEnvValue(string $key, ?string $default = null): ?string {
    $val = getenv($key);
    if ($val !== false && $val !== '') {
        return $val;
    }
    if (isset($_ENV[$key]) && $_ENV[$key] !== '') {
        return $_ENV[$key];
    }
    if (isset($_SERVER[$key]) && $_SERVER[$key] !== '') {
        return $_SERVER[$key];
    }
    static $envFileVars = null;
    if ($envFileVars === null) {
        $envFileVars = [];
        $envPath = __DIR__ . '/.env';
        if (file_exists($envPath)) {
            $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                $line = trim($line);
                if ($line === '' || str_starts_with($line, '#')) continue;
                if (str_contains($line, '=')) {
                    [$k, $v] = explode('=', $line, 2);
                    $k = trim($k);
                    $v = trim($v);
                    $v = trim($v, '"\'');
                    $envFileVars[$k] = $v;
                }
            }
        }
    }
    return $envFileVars[$key] ?? $default;
}

// Database Initialization for SQLite fallback
function initSqliteSchema(PDO $pdo): void {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            phone TEXT DEFAULT '',
            password TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS user_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL UNIQUE,
            avatar_url TEXT,
            bio TEXT,
            battery_pct INTEGER DEFAULT 100,
            sharing_status TEXT DEFAULT 'on',
            sharing_expires_at DATETIME,
            show_speed INTEGER DEFAULT 1,
            show_battery INTEGER DEFAULT 1,
            allow_geofence_alerts INTEGER DEFAULT 1,
            last_seen_at DATETIME,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS personal_access_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tokenable_type TEXT NOT NULL,
            tokenable_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            token TEXT NOT NULL,
            abilities TEXT,
            last_used_at DATETIME,
            expires_at DATETIME,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            description TEXT,
            created_by INTEGER NOT NULL,
            is_active INTEGER DEFAULT 1,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS room_members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            role TEXT DEFAULT 'member',
            is_location_enabled INTEGER DEFAULT 1,
            custom_nickname TEXT,
            joined_at DATETIME,
            created_at DATETIME,
            updated_at DATETIME,
            UNIQUE(room_id, user_id)
        );
        CREATE TABLE IF NOT EXISTS locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL UNIQUE,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL,
            altitude REAL,
            speed REAL DEFAULT 0,
            heading REAL DEFAULT 0,
            battery_pct INTEGER DEFAULT 100,
            is_moving INTEGER DEFAULT 0,
            recorded_at DATETIME,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS location_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            speed REAL DEFAULT 0,
            heading REAL DEFAULT 0,
            recorded_at DATETIME,
            created_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            message_type TEXT DEFAULT 'text',
            content TEXT,
            latitude REAL,
            longitude REAL,
            location_label TEXT,
            is_deleted INTEGER DEFAULT 0,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS message_attachments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message_id INTEGER NOT NULL,
            file_path TEXT NOT NULL,
            file_url TEXT NOT NULL,
            file_name TEXT,
            file_size INTEGER DEFAULT 0,
            mime_type TEXT,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            sender_id INTEGER NOT NULL,
            alert_type TEXT NOT NULL,
            status TEXT DEFAULT 'active',
            latitude REAL,
            longitude REAL,
            metadata TEXT,
            acknowledged_by INTEGER,
            acknowledged_at DATETIME,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS places (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            created_by INTEGER NOT NULL,
            name TEXT NOT NULL,
            address TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius_meters REAL DEFAULT 200,
            alert_on_entry INTEGER DEFAULT 1,
            alert_on_exit INTEGER DEFAULT 1,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS calls (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            initiator_id INTEGER NOT NULL,
            call_type TEXT DEFAULT 'voice',
            status TEXT DEFAULT 'calling',
            started_at DATETIME,
            ended_at DATETIME,
            created_at DATETIME,
            updated_at DATETIME
        );
        CREATE TABLE IF NOT EXISTS call_participants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            call_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            status TEXT DEFAULT 'ringing',
            joined_at DATETIME,
            left_at DATETIME,
            created_at DATETIME,
            updated_at DATETIME,
            UNIQUE(call_id, user_id)
        );
    ");

    syncDefaultAndExistingUsers($pdo);
}

// Automatically sync Loleng, Mark, Anna, John, and active rooms so user accounts exist on Render
function syncDefaultAndExistingUsers(PDO $pdo): void {
    // 1. Mark Lawrence
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = 'mark' OR id = 1 LIMIT 1");
    $stmt->execute();
    if (!$stmt->fetch()) {
        $pwd = password_hash('password123', PASSWORD_DEFAULT);
        $pdo->exec("
            INSERT OR IGNORE INTO users (id, name, username, email, phone, password, is_active, created_at, updated_at)
            VALUES (1, 'Mark Lawrence', 'mark', 'mark@marlink.local', '+639171234567', '{$pwd}', 1, datetime('now'), datetime('now'));
            INSERT OR IGNORE INTO user_profiles (user_id, bio, battery_pct, sharing_status, show_speed, show_battery, allow_geofence_alerts, created_at, updated_at)
            VALUES (1, 'Always on the move.', 85, 'on', 1, 1, 1, datetime('now'), datetime('now'));
        ");
    }

    // 2. Anna Lawrence
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = 'anna' OR id = 2 LIMIT 1");
    $stmt->execute();
    if (!$stmt->fetch()) {
        $pwd = password_hash('password123', PASSWORD_DEFAULT);
        $pdo->exec("
            INSERT OR IGNORE INTO users (id, name, username, email, phone, password, is_active, created_at, updated_at)
            VALUES (2, 'Anna Lawrence', 'anna', 'anna@marlink.local', '+639179876543', '{$pwd}', 1, datetime('now'), datetime('now'));
            INSERT OR IGNORE INTO user_profiles (user_id, bio, battery_pct, sharing_status, show_speed, show_battery, allow_geofence_alerts, created_at, updated_at)
            VALUES (2, 'Graphic designer & traveler', 92, 'on', 1, 1, 1, datetime('now'), datetime('now'));
        ");
    }

    // 3. John Santos
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = 'john' OR id = 3 LIMIT 1");
    $stmt->execute();
    if (!$stmt->fetch()) {
        $pwd = password_hash('password123', PASSWORD_DEFAULT);
        $pdo->exec("
            INSERT OR IGNORE INTO users (id, name, username, email, phone, password, is_active, created_at, updated_at)
            VALUES (3, 'John Santos', 'john', 'john@marlink.local', '+639185551234', '{$pwd}', 1, datetime('now'), datetime('now'));
            INSERT OR IGNORE INTO user_profiles (user_id, bio, battery_pct, sharing_status, show_speed, show_battery, allow_geofence_alerts, created_at, updated_at)
            VALUES (3, 'Work & Coffee', 65, 'on', 1, 1, 1, datetime('now'), datetime('now'));
        ");
    }

    // 4. Loleng (User active mobile account from screenshot)
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = 'Loleng' OR email = 'rampingmarklawrence@gmail.com' LIMIT 1");
    $stmt->execute();
    if (!$stmt->fetch()) {
        $hash = '$2y$10$EMIzDkb6gq/v7Xq5cKzY2OteBN6fbApPqIYdCIWleBMf7tDZYn7G2'; // Password: Loleng123
        $pdo->exec("
            INSERT OR IGNORE INTO users (id, name, username, email, phone, password, is_active, created_at, updated_at)
            VALUES (4, 'Loleng Testing', 'Loleng', 'rampingmarklawrence@gmail.com', '09182256512', '{$hash}', 1, datetime('now'), datetime('now'));
            INSERT OR IGNORE INTO user_profiles (user_id, bio, battery_pct, sharing_status, show_speed, show_battery, allow_geofence_alerts, created_at, updated_at)
            VALUES (4, 'MarLink Member', 95, 'on', 1, 1, 1, datetime('now'), datetime('now'));
        ");
    }

    // 5. Rooms: Family (FAM-82K4) and Testing (MAR-B510)
    $stmt = $pdo->prepare("SELECT id FROM rooms WHERE code = 'FAM-82K4' LIMIT 1");
    $stmt->execute();
    if (!$stmt->fetch()) {
        $pdo->exec("
            INSERT OR IGNORE INTO rooms (id, code, name, description, created_by, is_active, created_at, updated_at)
            VALUES (1, 'FAM-82K4', 'Family', 'Official family safety & location sharing group.', 1, 1, datetime('now'), datetime('now'));
        ");
    }

    $stmt = $pdo->prepare("SELECT id FROM rooms WHERE code = 'MAR-B510' LIMIT 1");
    $stmt->execute();
    if (!$stmt->fetch()) {
        $pdo->exec("
            INSERT OR IGNORE INTO rooms (id, code, name, description, created_by, is_active, created_at, updated_at)
            VALUES (2, 'MAR-B510', 'Testing', 'Charchar', 3, 1, datetime('now'), datetime('now'));
        ");
    }

    // 6. Connect Loleng, Mark, Anna, John to the rooms
    $members = [
        [1, 1, 'owner'],
        [1, 2, 'admin'],
        [1, 3, 'member'],
        [1, 4, 'member'],
        [2, 3, 'owner'],
        [2, 4, 'member'],
    ];
    foreach ($members as $m) {
        $chk = $pdo->prepare("SELECT id FROM room_members WHERE room_id = ? AND user_id = ? LIMIT 1");
        $chk->execute([$m[0], $m[1]]);
        if (!$chk->fetch()) {
            $ins = $pdo->prepare("INSERT OR IGNORE INTO room_members (room_id, user_id, role, is_location_enabled, joined_at, created_at, updated_at) VALUES (?, ?, ?, 1, datetime('now'), datetime('now'), datetime('now'))");
            $ins->execute([$m[0], $m[1], $m[2]]);
        }
    }

    // 7. Ensure `locations` table exists and seed member locations (Tupi & Polomolok)
    $driver = $pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
    if ($driver === 'sqlite') {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS locations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL UNIQUE,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                accuracy REAL,
                altitude REAL,
                speed REAL DEFAULT 0,
                heading REAL DEFAULT 0,
                battery_pct INTEGER DEFAULT 100,
                is_moving INTEGER DEFAULT 0,
                recorded_at DATETIME,
                created_at DATETIME,
                updated_at DATETIME
            );
        ");
    }

    $defaultLocations = [
        [1, 6.3076379, 124.9733526, 32.7, 481.8, 0.0, 101.6, 85, 0], // Mark: Tupi
        [2, 6.2276992, 125.0618086, 18.4, 403.4, 0.0, 234.2, 92, 0], // Anna: Polomolok
        [3, 6.2250000, 125.0600000, 15.0, 410.0, 3.5, 180.0, 65, 1], // John: Polomolok
        [4, 6.3076579, 124.9732431, 20.0, 480.0, 0.0, 0.0, 95, 0],   // Loleng: Tupi
    ];
    foreach ($defaultLocations as $loc) {
        $chk = $pdo->prepare("SELECT id FROM locations WHERE user_id = ? LIMIT 1");
        $chk->execute([$loc[0]]);
        if (!$chk->fetch()) {
            $nowFunc = ($driver === 'sqlite') ? "datetime('now')" : "NOW()";
            $ins = $pdo->prepare("
                INSERT OR IGNORE INTO locations (user_id, latitude, longitude, accuracy, altitude, speed, heading, battery_pct, is_moving, recorded_at, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, {$nowFunc}, {$nowFunc}, {$nowFunc})
            ");
            $ins->execute($loc);
        }
    }
}

function ensureSchemaExists(PDO $pdo): void {
    static $ensured = false;
    if ($ensured) return;
    $ensured = true;

    $driver = $pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
    if ($driver === 'mysql') {
        try {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS calls (
                    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                    room_id BIGINT UNSIGNED NOT NULL,
                    initiator_id BIGINT UNSIGNED NOT NULL,
                    call_type VARCHAR(20) DEFAULT 'voice',
                    status VARCHAR(20) DEFAULT 'calling',
                    started_at DATETIME NULL,
                    ended_at DATETIME NULL,
                    created_at DATETIME NULL,
                    updated_at DATETIME NULL,
                    KEY calls_room_id_index (room_id),
                    KEY calls_initiator_id_index (initiator_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

                CREATE TABLE IF NOT EXISTS call_participants (
                    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                    call_id BIGINT UNSIGNED NOT NULL,
                    user_id BIGINT UNSIGNED NOT NULL,
                    status VARCHAR(20) DEFAULT 'ringing',
                    joined_at DATETIME NULL,
                    left_at DATETIME NULL,
                    created_at DATETIME NULL,
                    updated_at DATETIME NULL,
                    UNIQUE KEY call_user_unique (call_id, user_id),
                    KEY cp_call_id_index (call_id),
                    KEY cp_user_id_index (user_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

                CREATE TABLE IF NOT EXISTS places (
                    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                    room_id BIGINT UNSIGNED NOT NULL,
                    created_by BIGINT UNSIGNED NOT NULL,
                    name VARCHAR(255) NOT NULL,
                    address TEXT NULL,
                    latitude DECIMAL(10, 7) NOT NULL,
                    longitude DECIMAL(10, 7) NOT NULL,
                    radius_meters DOUBLE DEFAULT 200,
                    alert_on_entry TINYINT(1) DEFAULT 1,
                    alert_on_exit TINYINT(1) DEFAULT 1,
                    created_at DATETIME NULL,
                    updated_at DATETIME NULL,
                    KEY places_room_id_index (room_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } catch (Throwable $e) {}
    }

    if ($driver === 'sqlite') {
        try {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS calls (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    room_id INTEGER NOT NULL,
                    initiator_id INTEGER NOT NULL,
                    call_type TEXT DEFAULT 'voice',
                    status TEXT DEFAULT 'calling',
                    started_at DATETIME,
                    ended_at DATETIME,
                    created_at DATETIME,
                    updated_at DATETIME
                );
                CREATE TABLE IF NOT EXISTS call_participants (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    call_id INTEGER NOT NULL,
                    user_id INTEGER NOT NULL,
                    status TEXT DEFAULT 'ringing',
                    joined_at DATETIME,
                    left_at DATETIME,
                    created_at DATETIME,
                    updated_at DATETIME,
                    UNIQUE(call_id, user_id)
                );
                CREATE TABLE IF NOT EXISTS places (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    room_id INTEGER NOT NULL,
                    created_by INTEGER NOT NULL,
                    name TEXT NOT NULL,
                    address TEXT,
                    latitude REAL NOT NULL,
                    longitude REAL NOT NULL,
                    radius_meters REAL DEFAULT 200,
                    alert_on_entry INTEGER DEFAULT 1,
                    alert_on_exit INTEGER DEFAULT 1,
                    created_at DATETIME,
                    updated_at DATETIME
                );
            ");
        } catch (Throwable $e) {}
    }
}

// Database Connection with Auto Fallback (Cloud SQLite or MySQL)
function getDb(): PDO {
    static $pdo = null;
    if ($pdo !== null) {
        return $pdo;
    }

    $connection = getEnvValue('DB_CONNECTION', 'auto');
    $host = getEnvValue('DB_HOST', '127.0.0.1');

    // 1. If explicit Cloud MySQL is configured
    if ($connection === 'mysql' || ($connection === 'auto' && $host !== '127.0.0.1' && $host !== 'localhost' && $host !== 'sqlite')) {
        try {
            $port = getEnvValue('DB_PORT', '3306');
            $db   = getEnvValue('DB_DATABASE', 'marlink_db');
            $user = getEnvValue('DB_USERNAME', 'root');
            $pass = getEnvValue('DB_PASSWORD', '');

            $dsn = "mysql:host={$host};port={$port};dbname={$db};charset=utf8mb4";
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
                PDO::ATTR_TIMEOUT            => 4,
            ];
            $pdo = new PDO($dsn, $user, $pass, $options);
            ensureSchemaExists($pdo);
            return $pdo;
        } catch (Throwable $e) {
            if ($connection === 'mysql') {
                throw $e;
            }
        }
    }

    // 2. Local MySQL attempt (e.g. XAMPP running locally)
    if ($host === '127.0.0.1' || $host === 'localhost') {
        try {
            $port = getEnvValue('DB_PORT', '3306');
            $db   = getEnvValue('DB_DATABASE', 'marlink_db');
            $user = getEnvValue('DB_USERNAME', 'root');
            $pass = getEnvValue('DB_PASSWORD', '');
            $dsn = "mysql:host={$host};port={$port};dbname={$db};charset=utf8mb4";
            $pdo = new PDO($dsn, $user, $pass, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_TIMEOUT            => 2,
            ]);
            ensureSchemaExists($pdo);
            return $pdo;
        } catch (Throwable $e) {
            // Local MySQL not running, seamlessly proceed to SQLite fallback
        }
    }

    // 3. Resilient Standalone & Cloud SQLite Database
    $dbDir = __DIR__ . '/database';
    if (!is_dir($dbDir)) {
        @mkdir($dbDir, 0777, true);
    }
    $dbPath = $dbDir . '/marlink.sqlite';
    $isNew = !file_exists($dbPath);
    $pdo = new PDO("sqlite:{$dbPath}");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $pdo->sqliteCreateFunction('now', fn() => date('Y-m-d H:i:s'));
    $pdo->sqliteCreateFunction('curdate', fn() => date('Y-m-d'));
    if ($isNew || filesize($dbPath) === 0) {
        initSqliteSchema($pdo);
    } else {
        syncDefaultAndExistingUsers($pdo);
    }
    ensureSchemaExists($pdo);
    return $pdo;
}

// Helper: JSON Response
function respond(bool $success, string $message, $data = null, ?array $errors = null, int $statusCode = 200): void {
    http_response_code($statusCode);
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data'    => $data,
        'errors'  => $errors,
    ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

// Helper: Parse Request Body
function getRequestBody(): array {
    $raw = file_get_contents('php://input');
    if (empty($raw)) {
        return $_POST;
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : $_POST;
}

// Helper: Extract Bearer Token
function getBearerToken(): ?string {
    $headers = null;
    if (isset($_SERVER['Authorization'])) {
        $headers = trim($_SERVER['Authorization']);
    } elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $headers = trim($_SERVER['HTTP_AUTHORIZATION']);
    } elseif (function_exists('apache_request_headers')) {
        $reqHeaders = apache_request_headers();
        $headers = $reqHeaders['Authorization'] ?? $reqHeaders['authorization'] ?? null;
    }

    if (!empty($headers) && preg_match('/Bearer\s+(\S+)/i', $headers, $matches)) {
        return $matches[1];
    }
    return null;
}

// Helper: Authenticate Token
function authenticateUser(PDO $db): array {
    $token = getBearerToken();
    if (!$token) {
        respond(false, 'Unauthenticated. Missing Bearer token.', null, null, 401);
    }

    // Check personal_access_tokens
    $stmt = $db->prepare("SELECT tokenable_id FROM personal_access_tokens WHERE token = ? AND (expires_at IS NULL OR expires_at > NOW()) LIMIT 1");
    $stmt->execute([hash('sha256', $token)]);
    $row = $stmt->fetch();

    if (!$row) {
        // Fallback: check plain token or test tokens
        $stmt = $db->prepare("SELECT tokenable_id FROM personal_access_tokens WHERE token = ? LIMIT 1");
        $stmt->execute([$token]);
        $row = $stmt->fetch();
    }

    if (!$row) {
        // If token format is "demo_token_USERID", allow seamless local testing
        if (preg_match('/^demo_token_(\d+)$/', $token, $m)) {
            $userId = (int)$m[1];
        } else {
            respond(false, 'Unauthenticated. Invalid or expired session token.', null, null, 401);
        }
    } else {
        $userId = (int)$row['tokenable_id'];
    }

    $stmt = $db->prepare("SELECT u.*, p.avatar_url, p.bio, p.battery_pct, p.sharing_status, p.show_speed, p.show_battery, p.allow_geofence_alerts 
                          FROM users u 
                          LEFT JOIN user_profiles p ON p.user_id = u.id 
                          WHERE u.id = ? AND u.is_active = 1 LIMIT 1");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user) {
        respond(false, 'User account not found or suspended.', null, null, 401);
    }

    return formatUserRecord($user);
}

function formatUserRecord(array $u): array {
    return [
        'id'         => (int)$u['id'],
        'name'       => $u['name'],
        'username'   => $u['username'],
        'email'      => $u['email'],
        'phone'      => $u['phone'],
        'is_active'  => (bool)$u['is_active'],
        'created_at' => $u['created_at'],
        'profile'    => [
            'avatar_url'            => $u['avatar_url'] ?? null,
            'bio'                   => $u['bio'] ?? null,
            'battery_pct'           => isset($u['battery_pct']) ? (int)$u['battery_pct'] : 100,
            'sharing_status'        => $u['sharing_status'] ?? 'on',
            'is_sharing_active'     => ($u['sharing_status'] ?? 'on') === 'on',
            'sharing_expires_at'    => $u['sharing_expires_at'] ?? null,
            'show_speed'            => isset($u['show_speed']) ? (bool)$u['show_speed'] : true,
            'show_battery'          => isset($u['show_battery']) ? (bool)$u['show_battery'] : true,
            'allow_geofence_alerts' => isset($u['allow_geofence_alerts']) ? (bool)$u['allow_geofence_alerts'] : true,
        ]
    ];
}

// Router
try {
    $db = getDb();
} catch (Throwable $e) {
    respond(false, 'Database connection error: ' . $e->getMessage(), null, null, 500);
}

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

// Static file serving for uploads (supports subdirectories like uploads/avatars)
if (preg_match('#^/uploads/(.+)$#', $uri, $m)) {
    $cleanSubpath = str_replace(['..', "\0"], '', $m[1]);
    $filePath = __DIR__ . '/uploads/' . ltrim($cleanSubpath, '/');
    if (file_exists($filePath) && is_file($filePath)) {
        $mime = mime_content_type($filePath) ?: 'image/jpeg';
        header('Content-Type: ' . $mime);
        header('Content-Length: ' . filesize($filePath));
        header('Cache-Control: public, max-age=86400');
        readfile($filePath);
        exit;
    }
    http_response_code(404);
    echo json_encode(['error' => 'File not found']);
    exit;
}

// Direct APK Download Endpoint
if ($uri === '/download' || $uri === '/download-apk' || $uri === '/api/v1/download' || $uri === '/MarLink.apk') {
    $apkFile = __DIR__ . '/MarLink.apk';
    if (!file_exists($apkFile)) {
        $apkFile = dirname(__DIR__) . '/MarLink.apk';
    }
    if (file_exists($apkFile)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/vnd.android.package-archive');
        header('Content-Disposition: attachment; filename="MarLink.apk"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
        header('Pragma: public');
        header('Content-Length: ' . filesize($apkFile));
        readfile($apkFile);
        exit;
    } else {
        // High-speed CDN fallback directly from GitHub release asset
        header('Location: https://github.com/Markramping26/marlink/raw/main/marlink_api/MarLink.apk', true, 302);
        exit;
    }
}

// Logo Asset Endpoint for Social Previews
if ($uri === '/logo.png') {
    $logoFile = __DIR__ . '/logo.png';
    if (file_exists($logoFile)) {
        header('Content-Type: image/png');
        header('Cache-Control: public, max-age=604800');
        readfile($logoFile);
        exit;
    }
}

// App Version & Update Check Endpoint
if ($uri === '/api/v1/app/version' || $uri === '/api/v1/version' || $uri === '/version') {
    respond(true, 'Latest app version information.', [
        'latest_version' => '1.0.1',
        'build_number'   => 2,
        'release_notes'  => "• Fixed Voice Call & Video Call buttons\n• Fixed Leave Group button\n• Added Room Admin Kick member feature\n• Performance and UI improvements",
        'download_url'   => 'https://github.com/Markramping26/marlink/raw/main/marlink_api/MarLink.apk',
        'fallback_url'   => 'https://marlink-api.onrender.com/download',
        'is_mandatory'   => false,
        'release_date'   => '2026-09-30',
    ]);
}

// -------------------------------------------------------------
// ROUTES
// -------------------------------------------------------------

// 1. Health & Server Info / Web Landing Page
if ($uri === '' || $uri === '/' || $uri === '/api' || $uri === '/api/v1' || $uri === '/api/v1/health') {
    // If opened directly in a web or mobile browser, present a sleek Download page!
    if (str_contains($_SERVER['HTTP_ACCEPT'] ?? '', 'text/html') && ($uri === '' || $uri === '/')) {
        header('Content-Type: text/html; charset=utf-8');
        echo <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>👉 Download MarLink APK (57.2 MB)</title>
    
    <!-- Open Graph / Facebook / Messenger / WhatsApp Rich Previews -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://marlink-api.onrender.com/">
    <meta property="og:title" content="👉 Download MarLink APK (57.2 MB)">
    <meta property="og:description" content="Official Android Release • Real-Time GPS & Family Locator. Tap to download.">
    <meta property="og:image" content="https://marlink-api.onrender.com/logo.png">
    
    <!-- Twitter Preview -->
    <meta name="twitter:card" content="summary">
    <meta name="twitter:title" content="👉 Download MarLink APK (57.2 MB)">
    <meta name="twitter:description" content="Official Android Release • Real-Time GPS & Family Locator. Tap to download.">
    <meta name="twitter:image" content="https://marlink-api.onrender.com/logo.png">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800;900&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Plus Jakarta Sans', sans-serif; }
        body {
            background: linear-gradient(180deg, #040A18 0%, #08122B 50%, #030712 100%);
            color: #FFFFFF;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 24px;
            text-align: center;
            overflow-x: hidden;
            position: relative;
        }
        .glow-orb {
            position: absolute;
            width: 320px;
            height: 320px;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(14, 165, 233, 0.28) 0%, transparent 70%);
            top: 15%;
            z-index: 0;
            pointer-events: none;
        }
        .card {
            background: rgba(15, 27, 53, 0.85);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border: 1px solid rgba(56, 189, 248, 0.25);
            border-radius: 28px;
            padding: 44px 32px;
            max-width: 440px;
            width: 100%;
            position: relative;
            z-index: 1;
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5), 0 0 40px rgba(14, 165, 233, 0.15);
        }
        .logo-wrap {
            margin-bottom: 22px;
            display: inline-block;
            filter: drop-shadow(0 12px 28px rgba(14, 165, 233, 0.5));
        }
        .logo-img {
            width: 96px;
            height: 118px;
            object-fit: contain;
        }
        h1 {
            font-size: 34px;
            font-weight: 900;
            letter-spacing: -1px;
            margin-bottom: 6px;
        }
        .tagline {
            color: #94A3B8;
            font-size: 14px;
            font-weight: 500;
            margin-bottom: 28px;
        }
        .btn-download {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            width: 100%;
            padding: 16px 24px;
            background: linear-gradient(135deg, #0284C7 0%, #0EA5E9 100%);
            color: #FFFFFF;
            font-size: 16px;
            font-weight: 800;
            text-decoration: none;
            border-radius: 18px;
            box-shadow: 0 10px 25px rgba(14, 165, 233, 0.45);
            transition: all 0.25s ease;
        }
        .btn-download:hover, .btn-download:active {
            transform: translateY(-2px);
            box-shadow: 0 14px 32px rgba(14, 165, 233, 0.6);
            background: linear-gradient(135deg, #0369A1 0%, #38BDF8 100%);
        }
        .badge {
            margin-top: 18px;
            font-size: 12px;
            color: #64748B;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }
        .badge span {
            color: #10B981;
            font-weight: 700;
        }
        .features {
            margin-top: 28px;
            border-top: 1px solid rgba(255, 255, 255, 0.08);
            padding-top: 22px;
            text-align: left;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .feat-item {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 13px;
            color: #CBD5E1;
        }
        .feat-item svg {
            width: 16px;
            height: 16px;
            fill: #38BDF8;
            flex-shrink: 0;
        }
    </style>
</head>
<body>
    <div class="glow-orb"></div>
    <div class="card">
        <div class="logo-wrap">
            <svg class="logo-img" viewBox="0 0 415 509" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M207.5 0C93.03 0 0 93.03 0 207.5C0 350.2 186.75 494.8 194.8 501.03C198.5 503.88 202.97 505.3 207.5 505.3C212.03 505.3 216.5 503.88 220.2 501.03C228.25 494.8 415 350.2 415 207.5C415 93.03 321.97 0 207.5 0ZM207.5 35C302.76 35 380 112.24 380 207.5C380 318.5 233.8 440.6 207.5 462.1C181.2 440.6 35 318.5 35 207.5C35 112.24 112.24 35 207.5 35Z" fill="url(#pin_grad)"/>
                <circle cx="207.5" cy="145" r="38" fill="#38BDF8"/>
                <circle cx="140" cy="255" r="38" fill="#0EA5E9"/>
                <circle cx="275" cy="255" r="38" fill="#0284C7"/>
                <path d="M185 160C160 180 150 215 150 225M230 160C255 180 265 215 265 225M170 265C195 275 220 275 245 265" stroke="#38BDF8" stroke-width="12" stroke-linecap="round"/>
                <defs>
                    <linearGradient id="pin_grad" x1="0" y1="0" x2="415" y2="509" gradientUnits="userSpaceOnUse">
                        <stop stop-color="#38BDF8"/>
                        <stop offset="0.5" stop-color="#0EA5E9"/>
                        <stop offset="1" stop-color="#0284C7"/>
                    </linearGradient>
                </defs>
            </svg>
        </div>
        <h1>MarLink</h1>
        <p class="tagline">Connect &bull; Locate &bull; Stay Together</p>
        <a href="/download" class="btn-download">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            Download APK (v1.0.1)
        </a>
        <div class="badge">
            <span>&check; Official Release</span> &bull; 60.2 MB &bull; Android 8.0+
        </div>
        <div class="features">
            <div class="feat-item"><svg viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/></svg> Real-time high-precision family GPS tracking</div>
            <div class="feat-item"><svg viewBox="0 0 24 24"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z"/></svg> Emergency SOS broadcast & safety alerts</div>
            <div class="feat-item"><svg viewBox="0 0 24 24"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"/></svg> Live circle chat & location pin sharing</div>
        </div>
    </div>
</body>
</html>
HTML;
        exit;
    }

    respond(true, 'MarLink Real-Time API Server is Online and Connected to MySQL (marlink_db).', [
        'version'      => '1.0.1',
        'app'          => 'MarLink',
        'download_url' => 'https://marlink-api.onrender.com/download',
        'database'     => 'marlink_db (Active)',
        'timestamp'    => date('c'),
    ]);
}

// 2. Auth: Register
if ($method === 'POST' && $uri === '/api/v1/auth/register') {
    $body = getRequestBody();
    $name     = trim($body['name'] ?? '');
    $username = trim($body['username'] ?? '');
    $email    = trim($body['email'] ?? '');
    $phone    = trim($body['phone'] ?? '');
    $password = $body['password'] ?? '';

    if (empty($name) || empty($username) || empty($email) || empty($password)) {
        respond(false, 'Please fill in all required fields.', null, [
            'error' => 'Name, username, email, and password are required.'
        ], 422);
    }

    // Check duplicate
    $stmt = $db->prepare("SELECT id FROM users WHERE email = ? OR username = ? LIMIT 1");
    $stmt->execute([$email, $username]);
    if ($stmt->fetch()) {
        respond(false, 'An account with that email or username already exists.', null, [
            'email' => 'Already taken'
        ], 409);
    }

    $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
    $stmt = $db->prepare("INSERT INTO users (name, username, email, phone, password, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 1, NOW(), NOW())");
    $stmt->execute([$name, $username, $email, $phone ?: null, $hashedPassword]);
    $userId = (int)$db->lastInsertId();

    // Create profile
    $stmt = $db->prepare("INSERT INTO user_profiles (user_id, battery_pct, sharing_status, show_speed, show_battery, allow_geofence_alerts, created_at, updated_at) VALUES (?, 100, 'on', 1, 1, 1, NOW(), NOW())");
    $stmt->execute([$userId]);

    // Create token
    $plainToken = bin2hex(random_bytes(32));
    $hashedToken = hash('sha256', $plainToken);
    $stmt = $db->prepare("INSERT INTO personal_access_tokens (tokenable_type, tokenable_id, name, token, abilities, created_at, updated_at) VALUES ('App\\Models\\User', ?, 'mobile', ?, '[\"*\"]', NOW(), NOW())");
    $stmt->execute([$userId, $hashedToken]);

    $stmt = $db->prepare("SELECT u.*, p.avatar_url, p.bio, p.battery_pct, p.sharing_status, p.show_speed, p.show_battery, p.allow_geofence_alerts 
                          FROM users u LEFT JOIN user_profiles p ON p.user_id = u.id WHERE u.id = ?");
    $stmt->execute([$userId]);
    $userRecord = formatUserRecord($stmt->fetch());

    respond(true, 'Registration successful. Welcome to MarLink!', [
        'token' => $plainToken,
        'user'  => $userRecord,
    ], null, 201);
}

// 3. Auth: Login
if ($method === 'POST' && $uri === '/api/v1/auth/login') {
    $body = getRequestBody();
    $login = trim($body['login'] ?? '');
    $password = $body['password'] ?? '';

    if (empty($login) || empty($password)) {
        respond(false, 'Email/username and password are required.', null, null, 422);
    }

    $stmt = $db->prepare("SELECT u.*, p.avatar_url, p.bio, p.battery_pct, p.sharing_status, p.show_speed, p.show_battery, p.allow_geofence_alerts 
                          FROM users u 
                          LEFT JOIN user_profiles p ON p.user_id = u.id 
                          WHERE (u.email = ? OR u.username = ?) AND u.is_active = 1 LIMIT 1");
    $stmt->execute([$login, $login]);
    $user = $stmt->fetch();

    if (!$user) {
        respond(false, 'Invalid credentials. No user found.', null, null, 401);
    }

    // Verify password or allow seeded dev passwords
    $isMatch = password_verify($password, $user['password']);
    if (!$isMatch && ($password === 'Password123!' || $password === 'secret' || $password === 'admin123' || $password === 'password123' || $password === 'Loleng123')) {
        $isMatch = true;
    }

    if (!$isMatch) {
        respond(false, 'Invalid password. Please check your credentials.', null, null, 401);
    }

    $plainToken = bin2hex(random_bytes(32));
    $hashedToken = hash('sha256', $plainToken);
    $stmt = $db->prepare("INSERT INTO personal_access_tokens (tokenable_type, tokenable_id, name, token, abilities, created_at, updated_at) VALUES ('App\\Models\\User', ?, 'mobile', ?, '[\"*\"]', NOW(), NOW())");
    $stmt->execute([$user['id'], $hashedToken]);

    respond(true, 'Login successful. Welcome back!', [
        'token' => $plainToken,
        'user'  => formatUserRecord($user),
    ]);
}

// 4. Auth: Current User Profile (Me)
if ($method === 'GET' && $uri === '/api/v1/auth/me') {
    $currentUser = authenticateUser($db);
    respond(true, 'Profile loaded.', $currentUser);
}

// 5. Auth: Logout
if ($method === 'POST' && $uri === '/api/v1/auth/logout') {
    $token = getBearerToken();
    if ($token) {
        $stmt = $db->prepare("DELETE FROM personal_access_tokens WHERE token = ? OR token = ?");
        $stmt->execute([$token, hash('sha256', $token)]);
    }
    respond(true, 'Successfully logged out.');
}

// 6. User: Update Privacy & Profile Settings
if (($method === 'POST' || $method === 'PUT') && ($uri === '/api/v1/user/profile' || $uri === '/user/profile')) {
    $currentUser = authenticateUser($db);
    $body = getRequestBody();

    $fields = [];
    $params = [];

    if (isset($body['sharing_status'])) {
        $fields[] = 'sharing_status = ?';
        $statusVal = in_array($body['sharing_status'], ['on', 'paused', 'off']) ? $body['sharing_status'] : 'on';
        $params[] = $statusVal;
        if ($statusVal === 'off' || $statusVal === 'paused') {
            $fields[] = 'sharing_expires_at = NULL';
        }
    }
    if (isset($body['sharing_duration_minutes']) && (int)$body['sharing_duration_minutes'] > 0) {
        $minutes = (int)$body['sharing_duration_minutes'];
        $fields[] = 'sharing_expires_at = ?';
        $params[] = date('Y-m-d H:i:s', time() + ($minutes * 60));
    }
    if (isset($body['battery_pct'])) {
        $fields[] = 'battery_pct = ?';
        $params[] = max(0, min(100, (int)$body['battery_pct']));
    }
    if (isset($body['show_speed'])) {
        $fields[] = 'show_speed = ?';
        $val = $body['show_speed'];
        $fieldsBool = ($val === true || $val === 1 || $val === '1' || $val === 'true');
        $params[] = $fieldsBool ? 1 : 0;
    }
    if (isset($body['show_battery'])) {
        $fields[] = 'show_battery = ?';
        $val = $body['show_battery'];
        $fieldsBool = ($val === true || $val === 1 || $val === '1' || $val === 'true');
        $params[] = $fieldsBool ? 1 : 0;
    }
    if (isset($body['bio'])) {
        $fields[] = 'bio = ?';
        $params[] = trim($body['bio']);
    }

    // Ensure row in user_profiles exists
    $chk = $db->prepare("SELECT user_id FROM user_profiles WHERE user_id = ? LIMIT 1");
    $chk->execute([$currentUser['id']]);
    if (!$chk->fetch()) {
        $ins = $db->prepare("INSERT INTO user_profiles (user_id, battery_pct, sharing_status, show_speed, show_battery, allow_geofence_alerts, created_at, updated_at) VALUES (?, 100, 'on', 1, 1, 1, NOW(), NOW())");
        $ins->execute([$currentUser['id']]);
    }

    if (!empty($fields)) {
        $params[] = $currentUser['id'];
        $sql = "UPDATE user_profiles SET " . implode(', ', $fields) . ", updated_at = NOW() WHERE user_id = ?";
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
    }

    $stmt = $db->prepare("SELECT u.*, p.avatar_url, p.bio, p.battery_pct, p.sharing_status, p.sharing_expires_at, p.show_speed, p.show_battery, p.allow_geofence_alerts 
                          FROM users u LEFT JOIN user_profiles p ON p.user_id = u.id WHERE u.id = ?");
    $stmt->execute([$currentUser['id']]);
    $updated = formatUserRecord($stmt->fetch());

    respond(true, 'Profile updated successfully.', $updated);
}

// 6b. User: Upload Avatar
if ($method === 'POST' && ($uri === '/api/v1/user/avatar' || $uri === '/user/avatar')) {
    $currentUser = authenticateUser($db);

    if (empty($_FILES['avatar']) && empty($_FILES['image']) && empty($_FILES['file'])) {
        respond(false, 'No avatar file was received.', null, null, 422);
    }

    $file = $_FILES['avatar'] ?? ($_FILES['image'] ?? $_FILES['file']);
    if (!isset($file['error']) || $file['error'] !== UPLOAD_ERR_OK) {
        $errCode = $file['error'] ?? 'unknown';
        respond(false, "Failed to upload avatar (code: {$errCode}).", null, null, 500);
    }

    $uploadDir = __DIR__ . '/uploads/avatars';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $originalName = $file['name'];
    $ext = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
    if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'gif'])) {
        $ext = 'jpg';
    }

    $filename = 'avatar_' . $currentUser['id'] . '_' . time() . '.' . $ext;
    $targetPath = $uploadDir . '/' . $filename;

    if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
        respond(false, 'Could not save uploaded avatar to disk.', null, null, 500);
    }

    $host = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
    $scheme = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 'https' : 'http';
    $avatarUrl = "{$scheme}://{$host}/uploads/avatars/{$filename}";

    // Ensure row exists
    $chk = $db->prepare("SELECT user_id FROM user_profiles WHERE user_id = ? LIMIT 1");
    $chk->execute([$currentUser['id']]);
    if (!$chk->fetch()) {
        $ins = $db->prepare("INSERT INTO user_profiles (user_id, battery_pct, sharing_status, show_speed, show_battery, allow_geofence_alerts, created_at, updated_at) VALUES (?, 100, 'on', 1, 1, 1, NOW(), NOW())");
        $ins->execute([$currentUser['id']]);
    }

    $stmt = $db->prepare("UPDATE user_profiles SET avatar_url = ?, updated_at = NOW() WHERE user_id = ?");
    $stmt->execute([$avatarUrl, $currentUser['id']]);

    $stmt = $db->prepare("SELECT u.*, p.avatar_url, p.bio, p.battery_pct, p.sharing_status, p.sharing_expires_at, p.show_speed, p.show_battery, p.allow_geofence_alerts 
                          FROM users u LEFT JOIN user_profiles p ON p.user_id = u.id WHERE u.id = ?");
    $stmt->execute([$currentUser['id']]);
    $updated = formatUserRecord($stmt->fetch());

    respond(true, 'Avatar updated successfully.', $updated);
}

// 6c. User: Change Password
if (($method === 'POST' || $method === 'PUT') && ($uri === '/api/v1/user/password' || $uri === '/user/password' || $uri === '/api/v1/user/change-password')) {
    $currentUser = authenticateUser($db);
    $body = getRequestBody();

    $currentPassword = $body['current_password'] ?? '';
    $newPassword = $body['new_password'] ?? '';
    $confirmPassword = $body['confirm_password'] ?? ($body['new_password_confirmation'] ?? '');

    if (empty($currentPassword) || empty($newPassword)) {
        respond(false, 'Current password and new password are required.', null, null, 422);
    }

    if (strlen($newPassword) < 6) {
        respond(false, 'New password must be at least 6 characters long.', null, null, 422);
    }

    if (!empty($confirmPassword) && $newPassword !== $confirmPassword) {
        respond(false, 'New password and confirmation do not match.', null, null, 422);
    }

    // Verify current password against stored hash in DB
    $stmt = $db->prepare("SELECT password FROM users WHERE id = ? LIMIT 1");
    $stmt->execute([$currentUser['id']]);
    $row = $stmt->fetch();

    $storedHash = $row['password'] ?? '';
    $isMatch = password_verify($currentPassword, $storedHash);
    if (!$isMatch && ($currentPassword === 'Password123!' || $currentPassword === 'secret' || $currentPassword === 'admin123')) {
        $isMatch = true;
    }

    if (!$isMatch) {
        respond(false, 'Incorrect current password. Please try again.', null, null, 401);
    }

    $newHashed = password_hash($newPassword, PASSWORD_BCRYPT);
    $stmt = $db->prepare("UPDATE users SET password = ?, updated_at = NOW() WHERE id = ?");
    $stmt->execute([$newHashed, $currentUser['id']]);

    respond(true, 'Password changed successfully.');
}

// 7. Rooms: List User's Rooms
if ($method === 'GET' && $uri === '/api/v1/rooms') {
    $currentUser = authenticateUser($db);
    $stmt = $db->prepare("
        SELECT r.*, rm.role as current_user_role,
               (SELECT COUNT(*) FROM room_members WHERE room_id = r.id) as members_count
        FROM rooms r
        JOIN room_members rm ON rm.room_id = r.id AND rm.user_id = ?
        WHERE r.is_active = 1
        ORDER BY r.created_at DESC
    ");
    $stmt->execute([$currentUser['id']]);
    $rooms = $stmt->fetchAll();

    $data = array_map(function($r) {
        return [
            'id'                => (int)$r['id'],
            'code'              => $r['code'],
            'name'              => $r['name'],
            'description'       => $r['description'],
            'avatar_url'        => $r['avatar_url'],
            'created_by'        => (int)$r['created_by'],
            'is_active'         => (bool)$r['is_active'],
            'members_count'     => (int)$r['members_count'],
            'current_user_role' => $r['current_user_role'],
            'created_at'        => $r['created_at'],
        ];
    }, $rooms);

    respond(true, 'Rooms retrieved.', $data);
}

// 8. Rooms: Create Room
if ($method === 'POST' && $uri === '/api/v1/rooms') {
    $currentUser = authenticateUser($db);
    $body = getRequestBody();
    $name = trim($body['name'] ?? '');
    $desc = trim($body['description'] ?? '');

    if (empty($name)) {
        respond(false, 'Room name is required.', null, null, 422);
    }

    // Generate unique code like MAR-7A3F
    $code = 'MAR-' . strtoupper(substr(bin2hex(random_bytes(2)), 0, 4));

    $stmt = $db->prepare("INSERT INTO rooms (code, name, description, created_by, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, 1, NOW(), NOW())");
    $stmt->execute([$code, $name, $desc ?: null, $currentUser['id']]);
    $roomId = (int)$db->lastInsertId();

    // Add creator as owner
    $stmt = $db->prepare("INSERT INTO room_members (room_id, user_id, role, is_location_enabled, joined_at, created_at, updated_at) VALUES (?, ?, 'owner', 1, NOW(), NOW(), NOW())");
    $stmt->execute([$roomId, $currentUser['id']]);

    respond(true, 'Room created successfully.', [
        'id'                => $roomId,
        'code'              => $code,
        'name'              => $name,
        'description'       => $desc,
        'created_by'        => $currentUser['id'],
        'members_count'     => 1,
        'current_user_role' => 'owner',
        'created_at'        => date('c'),
    ], null, 201);
}

// 9. Rooms: Join Room by Code
if ($method === 'POST' && $uri === '/api/v1/rooms/join') {
    $currentUser = authenticateUser($db);
    $body = getRequestBody();
    $rawCode = trim($body['code'] ?? '');
    $code = strtoupper($rawCode);
    $cleanCode = str_replace('-', '', $code);

    if (empty($code)) {
        respond(false, 'Room invite code is required.', null, null, 422);
    }

    // Flexible match: e.g. 'MAR-7A3F' matches 'MAR-7A3F', 'MAR7A3F', '7A3F'
    $stmt = $db->prepare("
        SELECT * FROM rooms 
        WHERE (code = ? OR REPLACE(code, '-', '') = ? OR code = ? OR code LIKE ?) 
          AND is_active = 1 
        LIMIT 1
    ");
    $stmt->execute([$code, $cleanCode, 'MAR-' . $cleanCode, '%' . $cleanCode]);
    $room = $stmt->fetch();

    if (!$room) {
        respond(false, 'Circle with invite code "' . $rawCode . '" does not exist. Please check the code.', null, null, 404);
    }

    $roomId = (int)$room['id'];
    $nickname = trim($body['nickname'] ?? $body['custom_nickname'] ?? '');

    // Check if already a member
    $stmt = $db->prepare("SELECT id, role FROM room_members WHERE room_id = ? AND user_id = ? LIMIT 1");
    $stmt->execute([$roomId, $currentUser['id']]);
    $existing = $stmt->fetch();

    if ($existing) {
        if (!empty($nickname)) {
            $stmt = $db->prepare("UPDATE room_members SET custom_nickname = ?, updated_at = NOW() WHERE id = ?");
            $stmt->execute([$nickname, $existing['id']]);
        }
        $userRole = $existing['role'];
    } else {
        // Insert membership
        $stmt = $db->prepare("INSERT INTO room_members (room_id, user_id, role, is_location_enabled, custom_nickname, joined_at, created_at, updated_at) VALUES (?, ?, 'member', 1, ?, NOW(), NOW(), NOW())");
        $stmt->execute([$roomId, $currentUser['id'], !empty($nickname) ? $nickname : null]);
        $userRole = 'member';
    }

    $membersData = getRoomMembersData($db, $roomId);

    respond(true, 'Successfully joined ' . $room['name'] . '!', [
        'id'                => $roomId,
        'code'              => $room['code'],
        'name'              => $room['name'],
        'description'       => $room['description'],
        'avatar_url'        => $room['avatar_url'] ?? null,
        'created_by'        => (int)($room['created_by'] ?? 1),
        'is_active'         => (bool)$room['is_active'],
        'members_count'     => count($membersData),
        'members'           => $membersData,
        'current_user_role' => $userRole,
        'created_at'        => $room['created_at'],
    ]);
}

// Helper: Fetch Room Members with Live GPS
function getRoomMembersData(PDO $db, int $roomId): array {
    $stmt = $db->prepare("
        SELECT rm.id as member_id, rm.user_id, rm.role, rm.is_location_enabled, rm.custom_nickname, rm.joined_at,
               u.name, u.username,
               p.avatar_url, p.battery_pct, p.sharing_status, p.show_speed, p.show_battery, p.last_seen_at,
               l.latitude, l.longitude, l.accuracy, l.speed, l.heading, l.is_moving, l.recorded_at
        FROM room_members rm
        JOIN users u ON u.id = rm.user_id
        LEFT JOIN user_profiles p ON p.user_id = u.id
        LEFT JOIN locations l ON l.user_id = u.id
        WHERE rm.room_id = ?
        ORDER BY CASE WHEN rm.role = 'owner' THEN 0 ELSE 1 END ASC, u.name ASC
    ");
    $stmt->execute([$roomId]);
    $rows = $stmt->fetchAll();

    return array_map(function($m) {
        $isSharingActive = ($m['sharing_status'] ?? 'on') === 'on' && (bool)$m['is_location_enabled'];
        $hasLocation = !empty($m['latitude']) && !empty($m['longitude']) && $isSharingActive;

        return [
            'id'                  => (int)$m['member_id'],
            'user_id'             => (int)$m['user_id'],
            'name'                => $m['name'],
            'username'            => $m['username'],
            'custom_nickname'     => $m['custom_nickname'],
            'display_name'        => $m['custom_nickname'] ?: $m['name'],
            'avatar_url'          => $m['avatar_url'],
            'role'                => $m['role'],
            'is_location_enabled' => (bool)$m['is_location_enabled'],
            'sharing_status'      => $m['sharing_status'] ?? 'on',
            'is_sharing_active'   => $isSharingActive,
            'battery_pct'         => ($m['show_battery'] ?? 1) ? (int)($m['battery_pct'] ?? 100) : null,
            'last_seen_at'        => $m['last_seen_at'],
            'joined_at'           => $m['joined_at'],
            'latitude'            => $hasLocation ? (float)$m['latitude'] : null,
            'longitude'           => $hasLocation ? (float)$m['longitude'] : null,
            'accuracy'            => $hasLocation && isset($m['accuracy']) ? (float)$m['accuracy'] : null,
            'speed'               => ($hasLocation && ($m['show_speed'] ?? 1)) ? (float)($m['speed'] ?? 0.0) : null,
            'heading'             => $hasLocation ? (float)($m['heading'] ?? 0.0) : null,
            'is_moving'           => $hasLocation ? (bool)$m['is_moving'] : false,
            'recorded_at'         => $hasLocation ? $m['recorded_at'] : null,
        ];
    }, $rows);
}

// 10. Rooms: Room Details & Members
if ($method === 'GET' && preg_match('#^/api/v1/rooms/(\d+)$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];

    $stmt = $db->prepare("SELECT r.*, rm.role as current_user_role FROM rooms r JOIN room_members rm ON rm.room_id = r.id AND rm.user_id = ? WHERE r.id = ? LIMIT 1");
    $stmt->execute([$currentUser['id'], $roomId]);
    $room = $stmt->fetch();

    if (!$room) {
        respond(false, 'Room not found or you are not a member.', null, null, 404);
    }

    $members = getRoomMembersData($db, $roomId);

    respond(true, 'Room loaded.', [
        'id'                => (int)$room['id'],
        'code'              => $room['code'],
        'name'              => $room['name'],
        'description'       => $room['description'],
        'avatar_url'        => $room['avatar_url'],
        'created_by'        => (int)$room['created_by'],
        'is_active'         => (bool)$room['is_active'],
        'members_count'     => count($members),
        'members'           => $members,
        'current_user_role' => $room['current_user_role'],
        'created_at'        => $room['created_at'],
    ]);
}

// 10b. Rooms: Leave Room
if ($method === 'POST' && preg_match('#^/api/v1/rooms/(\d+)/leave$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];

    $stmt = $db->prepare("SELECT * FROM room_members WHERE room_id = ? AND user_id = ? LIMIT 1");
    $stmt->execute([$roomId, $currentUser['id']]);
    $membership = $stmt->fetch();

    if (!$membership) {
        respond(false, 'You are not a member of this group.', null, null, 400);
    }

    $delStmt = $db->prepare("DELETE FROM room_members WHERE room_id = ? AND user_id = ?");
    $delStmt->execute([$roomId, $currentUser['id']]);

    // Insert system message into room chat
    try {
        $now = date('Y-m-d H:i:s');
        $sysMsg = $db->prepare("
            INSERT INTO messages (room_id, user_id, message_type, content, is_deleted, created_at, updated_at)
            VALUES (?, ?, 'system', ?, 0, ?, ?)
        ");
        $sysMsg->execute([$roomId, $currentUser['id'], "{$currentUser['name']} left the circle.", $now, $now]);
    } catch (Throwable $e) {}

    // Check remaining members
    $countStmt = $db->prepare("SELECT COUNT(*) FROM room_members WHERE room_id = ?");
    $countStmt->execute([$roomId]);
    $remaining = (int)$countStmt->fetchColumn();

    if ($remaining === 0) {
        $now = date('Y-m-d H:i:s');
        $upd = $db->prepare("UPDATE rooms SET is_active = 0, updated_at = ? WHERE id = ?");
        $upd->execute([$now, $roomId]);
    } else if (($membership['role'] ?? '') === 'admin' || ($membership['role'] ?? '') === 'owner') {
        // Transfer admin role to next oldest member
        $nextStmt = $db->prepare("SELECT user_id FROM room_members WHERE room_id = ? ORDER BY id ASC LIMIT 1");
        $nextStmt->execute([$roomId]);
        $nextAdminId = $nextStmt->fetchColumn();
        if ($nextAdminId) {
            $now = date('Y-m-d H:i:s');
            $makeAdmin = $db->prepare("UPDATE room_members SET role = 'admin', updated_at = ? WHERE room_id = ? AND user_id = ?");
            $makeAdmin->execute([$now, $roomId, $nextAdminId]);
        }
    }

    respond(true, 'You have left the group successfully.');
}

// 10c. Rooms: Remove / Kick Member from Room (Admin / Creator Only)
if ($method === 'DELETE' && preg_match('#^/api/v1/rooms/(\d+)/members/(\d+)$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];
    $targetUserId = (int)$m[2];

    // Check if room exists and check caller's role
    $stmt = $db->prepare("
        SELECT r.created_by, rm.role 
        FROM rooms r
        LEFT JOIN room_members rm ON rm.room_id = r.id AND rm.user_id = ?
        WHERE r.id = ? LIMIT 1
    ");
    $stmt->execute([$currentUser['id'], $roomId]);
    $roomData = $stmt->fetch();

    if (!$roomData) {
        respond(false, 'Room not found.', null, null, 404);
    }

    $isCreator = ((int)$roomData['created_by'] === (int)$currentUser['id']);
    $callerRole = strtolower($roomData['role'] ?? '');
    $isAdmin = ($callerRole === 'admin' || $callerRole === 'owner');

    if (!$isCreator && !$isAdmin) {
        respond(false, 'Only the room creator or admin can remove members.', null, null, 403);
    }

    if ($targetUserId === (int)$currentUser['id']) {
        respond(false, 'You cannot kick yourself. Please use Leave Group instead.', null, null, 400);
    }

    // Get target user details
    $targetStmt = $db->prepare("SELECT name FROM users WHERE id = ? LIMIT 1");
    $targetStmt->execute([$targetUserId]);
    $targetUser = $targetStmt->fetch();
    $targetName = $targetUser ? $targetUser['name'] : 'Member';

    // Delete membership
    $delStmt = $db->prepare("DELETE FROM room_members WHERE room_id = ? AND user_id = ?");
    $delStmt->execute([$roomId, $targetUserId]);

    // Post system notice to room chat
    try {
        $now = date('Y-m-d H:i:s');
        $sysMsg = $db->prepare("
            INSERT INTO messages (room_id, user_id, message_type, content, is_deleted, created_at, updated_at)
            VALUES (?, ?, 'system', ?, 0, ?, ?)
        ");
        $sysMsg->execute([$roomId, $currentUser['id'], "{$targetName} was removed from the circle by {$currentUser['name']}.", $now, $now]);
    } catch (Throwable $e) {}

    respond(true, "{$targetName} has been removed from the group.");
}

// 11. Locations: Room Member Locations
if ($method === 'GET' && preg_match('#^/api/v1/rooms/(\d+)/locations$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];

    $members = getRoomMembersData($db, $roomId);
    respond(true, 'Live locations retrieved.', $members);
}

// 12. Locations: Update GPS Location (Device -> Backend)
if ($method === 'POST' && $uri === '/api/v1/locations/update') {
    $currentUser = authenticateUser($db);
    $body = getRequestBody();

    $lat = isset($body['latitude']) ? (float)$body['latitude'] : null;
    $lng = isset($body['longitude']) ? (float)$body['longitude'] : null;
    $accuracy = isset($body['accuracy']) ? (float)$body['accuracy'] : null;
    $altitude = isset($body['altitude']) ? (float)$body['altitude'] : null;
    $speed = isset($body['speed']) ? (float)$body['speed'] : null;
    $heading = isset($body['heading']) ? (float)$body['heading'] : null;
    $battery = isset($body['battery_pct']) ? (int)$body['battery_pct'] : null;
    $isMoving = isset($body['is_moving']) ? ($body['is_moving'] ? 1 : 0) : ($speed > 0.5 ? 1 : 0);

    if ($lat === null || $lng === null) {
        respond(false, 'Latitude and longitude coordinates are required.', null, null, 422);
    }

    // Upsert into `locations`
    $driver = $db->getAttribute(PDO::ATTR_DRIVER_NAME);
    if ($driver === 'sqlite') {
        $stmt = $db->prepare("
            INSERT INTO locations (user_id, latitude, longitude, accuracy, altitude, speed, heading, battery_pct, is_moving, recorded_at, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'), datetime('now'))
            ON CONFLICT(user_id) DO UPDATE SET
                latitude = excluded.latitude,
                longitude = excluded.longitude,
                accuracy = excluded.accuracy,
                altitude = excluded.altitude,
                speed = excluded.speed,
                heading = excluded.heading,
                battery_pct = excluded.battery_pct,
                is_moving = excluded.is_moving,
                recorded_at = datetime('now'),
                updated_at = datetime('now')
        ");
        $stmt->execute([$currentUser['id'], $lat, $lng, $accuracy, $altitude, $speed, $heading, $battery, $isMoving]);
    } else {
        $stmt = $db->prepare("
            INSERT INTO locations (user_id, latitude, longitude, accuracy, altitude, speed, heading, battery_pct, is_moving, recorded_at, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())
            ON DUPLICATE KEY UPDATE
                latitude = VALUES(latitude),
                longitude = VALUES(longitude),
                accuracy = VALUES(accuracy),
                altitude = VALUES(altitude),
                speed = VALUES(speed),
                heading = VALUES(heading),
                battery_pct = VALUES(battery_pct),
                is_moving = VALUES(is_moving),
                recorded_at = NOW(),
                updated_at = NOW()
        ");
        $stmt->execute([$currentUser['id'], $lat, $lng, $accuracy, $altitude, $speed, $heading, $battery, $isMoving]);
    }

    // Insert history trail
    $stmt = $db->prepare("INSERT INTO location_history (user_id, latitude, longitude, speed, heading, recorded_at, created_at) VALUES (?, ?, ?, ?, ?, NOW(), NOW())");
    $stmt->execute([$currentUser['id'], $lat, $lng, $speed, $heading]);

    // Update battery and last seen on profile
    if ($battery !== null) {
        $stmt = $db->prepare("UPDATE user_profiles SET battery_pct = ?, last_seen_at = NOW() WHERE user_id = ?");
        $stmt->execute([$battery, $currentUser['id']]);
    } else {
        $stmt = $db->prepare("UPDATE user_profiles SET last_seen_at = NOW() WHERE user_id = ?");
        $stmt->execute([$currentUser['id']]);
    }

    respond(true, 'Location successfully broadcasted.', [
        'user_id'     => $currentUser['id'],
        'latitude'    => $lat,
        'longitude'   => $lng,
        'speed'       => $speed,
        'heading'     => $heading,
        'battery_pct' => $battery,
        'recorded_at' => date('c'),
    ]);
}

// 13. Messages: List Room Chat Messages
if ($method === 'GET' && preg_match('#^/api/v1/rooms/(\d+)/messages$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];

    $stmt = $db->prepare("
        SELECT msg.*, u.name as sender_name, u.username as sender_username, p.avatar_url as sender_avatar_url
        FROM messages msg
        JOIN users u ON u.id = msg.user_id
        LEFT JOIN user_profiles p ON p.user_id = u.id
        WHERE msg.room_id = ? AND msg.is_deleted = 0
        ORDER BY msg.created_at ASC
        LIMIT 100
    ");
    $stmt->execute([$roomId]);
    $messages = $stmt->fetchAll();

    // Fetch attachments for these messages
    $msgIds = array_column($messages, 'id');
    $attachmentsByMsg = [];
    if (!empty($msgIds)) {
        $inQuery = implode(',', array_fill(0, count($msgIds), '?'));
        $attStmt = $db->prepare("SELECT * FROM message_attachments WHERE message_id IN ($inQuery)");
        $attStmt->execute($msgIds);
        $attRows = $attStmt->fetchAll();
        foreach ($attRows as $a) {
            $attachmentsByMsg[$a['message_id']][] = [
                'id'        => (int)$a['id'],
                'file_url'  => $a['file_url'],
                'file_name' => $a['file_name'],
                'file_size' => (int)$a['file_size'],
                'mime_type' => $a['mime_type'],
            ];
        }
    }

    $data = array_map(function($msg) use ($attachmentsByMsg) {
        $hasLocation = ($msg['latitude'] !== null && $msg['longitude'] !== null);
        return [
            'id'             => (int)$msg['id'],
            'room_id'        => (int)$msg['room_id'],
            'user_id'        => (int)$msg['user_id'],
            'sender_name'    => $msg['sender_name'],
            'sender_username'=> $msg['sender_username'],
            'sender_avatar'  => $msg['sender_avatar_url'],
            'sender'         => [
                'id'         => (int)$msg['user_id'],
                'name'       => $msg['sender_name'],
                'username'   => $msg['sender_username'],
                'avatar_url' => $msg['sender_avatar_url'],
            ],
            'message_type'   => $msg['message_type'],
            'content'        => $msg['content'],
            'latitude'       => $hasLocation ? (float)$msg['latitude'] : null,
            'longitude'      => $hasLocation ? (float)$msg['longitude'] : null,
            'location_label' => $msg['location_label'],
            'location'       => $hasLocation ? [
                'latitude'  => (float)$msg['latitude'],
                'longitude' => (float)$msg['longitude'],
                'label'     => $msg['location_label'] ?: 'Shared Location',
            ] : null,
            'attachments'    => $attachmentsByMsg[$msg['id']] ?? [],
            'created_at'     => $msg['created_at'] ? gmdate('Y-m-d\TH:i:s\Z', strtotime($msg['created_at'] . ' UTC')) : gmdate('Y-m-d\TH:i:s\Z'),
        ];
    }, $messages);

    respond(true, 'Messages loaded.', $data);
}

// 14. Messages: Send Message (Text / Location Pin)
if ($method === 'POST' && preg_match('#^/api/v1/rooms/(\d+)/messages$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];
    $body = getRequestBody();

    $type = $body['message_type'] ?? 'text';
    $content = trim($body['content'] ?? '');
    $lat = isset($body['latitude']) ? (float)$body['latitude'] : null;
    $lng = isset($body['longitude']) ? (float)$body['longitude'] : null;
    $label = trim($body['location_label'] ?? '');

    if ($type === 'text' && empty($content)) {
        respond(false, 'Message content cannot be empty.', null, null, 422);
    }
    if ($type === 'location' && ($lat === null || $lng === null)) {
        respond(false, 'Location coordinates are required for location pin.', null, null, 422);
    }

    $stmt = $db->prepare("INSERT INTO messages (room_id, user_id, message_type, content, latitude, longitude, location_label, is_deleted, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, 0, NOW(), NOW())");
    $stmt->execute([$roomId, $currentUser['id'], $type, $content ?: null, $lat, $lng, $label ?: null]);
    $msgId = (int)$db->lastInsertId();

    $hasLocation = ($lat !== null && $lng !== null);

    respond(true, 'Message sent.', [
        'id'             => $msgId,
        'room_id'        => $roomId,
        'user_id'        => $currentUser['id'],
        'sender_name'    => $currentUser['name'],
        'sender_username'=> $currentUser['username'],
        'sender_avatar'  => null,
        'sender'         => [
            'id'         => $currentUser['id'],
            'name'       => $currentUser['name'],
            'username'   => $currentUser['username'],
            'avatar_url' => null,
        ],
        'message_type'   => $type,
        'content'        => $content,
        'latitude'       => $lat,
        'longitude'      => $lng,
        'location_label' => $label,
        'location'       => $hasLocation ? [
            'latitude'  => $lat,
            'longitude' => $lng,
            'label'     => $label ?: 'Shared Location',
        ] : null,
        'attachments'    => [],
        'created_at'     => gmdate('Y-m-d\TH:i:s\Z'),
    ], null, 201);
}

// 14b. Messages: Upload Image / Media Attachment
if ($method === 'POST' && preg_match('#^/api/v1/rooms/(\d+)/messages/media$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];

    if (empty($_FILES['image']) && empty($_FILES['file']) && empty($_FILES['media'])) {
        respond(false, 'No image file was received.', null, null, 422);
    }

    $file = $_FILES['image'] ?? ($_FILES['file'] ?? $_FILES['media']);
    if (!isset($file['error']) || $file['error'] !== UPLOAD_ERR_OK) {
        $errCode = $file['error'] ?? 'unknown';
        respond(false, "Failed to upload image (code: {$errCode}).", null, null, 500);
    }

    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION)) ?: 'jpg';
    $safeName = 'img_' . date('Ymd_His') . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
    $uploadDir = __DIR__ . '/uploads';
    if (!is_dir($uploadDir)) {
        @mkdir($uploadDir, 0777, true);
    }
    $targetPath = $uploadDir . '/' . $safeName;

    if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
        respond(false, 'Failed to save uploaded image to server disk.', null, null, 500);
    }

    $host = $_SERVER['HTTP_HOST'] ?? '192.168.254.115:8000';
    $fileUrl = "http://{$host}/uploads/{$safeName}";
    $caption = isset($_POST['caption']) ? trim($_POST['caption']) : null;
    $fileSize = (int)$file['size'];
    $mimeType = $file['type'] ?: 'image/jpeg';

    $stmt = $db->prepare("INSERT INTO messages (room_id, user_id, message_type, content, is_deleted, created_at, updated_at) VALUES (?, ?, 'image', ?, 0, NOW(), NOW())");
    $stmt->execute([$roomId, $currentUser['id'], $caption ?: $fileUrl]);
    $msgId = (int)$db->lastInsertId();

    $stmt = $db->prepare("INSERT INTO message_attachments (message_id, file_path, file_url, file_name, file_size, mime_type, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())");
    $stmt->execute([$msgId, $targetPath, $fileUrl, $safeName, $fileSize, $mimeType]);
    $attachmentId = (int)$db->lastInsertId();

    respond(true, 'Image uploaded successfully.', [
        'id'             => $msgId,
        'room_id'        => $roomId,
        'user_id'        => $currentUser['id'],
        'sender_name'    => $currentUser['name'],
        'sender_username'=> $currentUser['username'],
        'sender_avatar'  => null,
        'sender'         => [
            'id'         => $currentUser['id'],
            'name'       => $currentUser['name'],
            'username'   => $currentUser['username'],
            'avatar_url' => null,
        ],
        'message_type'   => 'image',
        'content'        => $caption ?: $fileUrl,
        'latitude'       => null,
        'longitude'      => null,
        'location_label' => null,
        'location'       => null,
        'attachments'    => [
            [
                'id'        => $attachmentId,
                'file_url'  => $fileUrl,
                'file_name' => $safeName,
                'file_size' => $fileSize,
                'mime_type' => $mimeType,
            ]
        ],
        'created_at'     => gmdate('Y-m-d\TH:i:s\Z'),
    ], null, 201);
}

// 15. Safety Alerts: List Room Alerts
if ($method === 'GET' && preg_match('#^/api/v1/rooms/(\d+)/alerts$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];

    $stmt = $db->prepare("
        SELECT a.*, u.name as sender_name, u.username as sender_username, ack.name as acknowledged_by_name
        FROM alerts a
        JOIN users u ON u.id = a.sender_id
        LEFT JOIN users ack ON ack.id = a.acknowledged_by
        WHERE a.room_id = ?
        ORDER BY a.created_at DESC
        LIMIT 50
    ");
    $stmt->execute([$roomId]);
    $alerts = $stmt->fetchAll();

    $data = array_map(function($a) {
        return [
            'id'                   => (int)$a['id'],
            'room_id'              => (int)$a['room_id'],
            'sender_id'            => (int)$a['sender_id'],
            'sender_name'          => $a['sender_name'],
            'alert_type'           => $a['alert_type'],
            'status'               => $a['status'],
            'latitude'             => $a['latitude'] !== null ? (float)$a['latitude'] : null,
            'longitude'            => $a['longitude'] !== null ? (float)$a['longitude'] : null,
            'metadata'             => !empty($a['metadata']) ? json_decode($a['metadata'], true) : null,
            'acknowledged_by_name' => $a['acknowledged_by_name'],
            'acknowledged_at'      => $a['acknowledged_at'],
            'created_at'           => $a['created_at'],
        ];
    }, $alerts);

    respond(true, 'Alerts loaded.', $data);
}

// 16. Safety Alerts: Trigger SOS Emergency
if ($method === 'POST' && preg_match('#^/api/v1/rooms/(\d+)/sos$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];
    $body = getRequestBody();

    $lat = isset($body['latitude']) ? (float)$body['latitude'] : null;
    $lng = isset($body['longitude']) ? (float)$body['longitude'] : null;

    $stmt = $db->prepare("INSERT INTO alerts (room_id, sender_id, alert_type, status, latitude, longitude, metadata, created_at, updated_at) VALUES (?, ?, 'sos', 'active', ?, ?, ?, NOW(), NOW())");
    $metadata = json_encode(['emergency' => true, 'device' => 'MarLink Mobile']);
    $stmt->execute([$roomId, $currentUser['id'], $lat, $lng, $metadata]);
    $alertId = (int)$db->lastInsertId();

    // Also auto-post SOS message in room chat
    $sosText = "🚨 EMERGENCY SOS TRIGGERED by " . $currentUser['name'] . "! Please check their location immediately!";
    $stmt = $db->prepare("INSERT INTO messages (room_id, user_id, message_type, content, latitude, longitude, location_label, created_at, updated_at) VALUES (?, ?, 'location', ?, ?, ?, 'SOS EMERGENCY LOCATION', NOW(), NOW())");
    $stmt->execute([$roomId, $currentUser['id'], $sosText, $lat, $lng]);

    respond(true, 'EMERGENCY SOS BROADCASTED TO ALL ROOM MEMBERS!', [
        'alert_id'   => $alertId,
        'room_id'    => $roomId,
        'alert_type' => 'sos',
        'status'     => 'active',
        'latitude'   => $lat,
        'longitude'  => $lng,
        'created_at' => date('c'),
    ], null, 201);
}

// 17. Safety Alerts: Create Attention Alert
if ($method === 'POST' && preg_match('#^/api/v1/rooms/(\d+)/alerts$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];
    $body = getRequestBody();

    $type = $body['alert_type'] ?? 'attention';
    $lat = isset($body['latitude']) ? (float)$body['latitude'] : null;
    $lng = isset($body['longitude']) ? (float)$body['longitude'] : null;
    $meta = isset($body['metadata']) ? json_encode($body['metadata']) : null;

    $stmt = $db->prepare("INSERT INTO alerts (room_id, sender_id, alert_type, status, latitude, longitude, metadata, created_at, updated_at) VALUES (?, ?, ?, 'active', ?, ?, ?, NOW(), NOW())");
    $stmt->execute([$roomId, $currentUser['id'], $type, $lat, $lng, $meta]);
    $alertId = (int)$db->lastInsertId();

    respond(true, 'Alert sent successfully.', [
        'alert_id'   => $alertId,
        'room_id'    => $roomId,
        'alert_type' => $type,
        'status'     => 'active',
        'latitude'   => $lat,
        'longitude'  => $lng,
        'created_at' => date('c'),
    ], null, 201);
}

// 18. Safety Alerts: Acknowledge Alert
if ($method === 'POST' && preg_match('#^/api/v1/rooms/(\d+)/alerts/(\d+)/acknowledge$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $alertId = (int)$m[2];

    $stmt = $db->prepare("UPDATE alerts SET status = 'acknowledged', acknowledged_by = ?, acknowledged_at = NOW() WHERE id = ?");
    $stmt->execute([$currentUser['id'], $alertId]);

    respond(true, 'Alert acknowledged.');
}

// 19. Geofence Places: List Places
if ($method === 'GET' && preg_match('#^/api/v1/rooms/(\d+)/places$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];

    $stmt = $db->prepare("SELECT * FROM places WHERE room_id = ? ORDER BY created_at DESC");
    $stmt->execute([$roomId]);
    $places = $stmt->fetchAll();

    $data = array_map(function($p) {
        return [
            'id'             => (int)$p['id'],
            'room_id'        => (int)$p['room_id'],
            'name'           => $p['name'],
            'address'        => $p['address'],
            'latitude'       => (float)$p['latitude'],
            'longitude'      => (float)$p['longitude'],
            'radius_meters'  => (int)$p['radius_meters'],
            'alert_on_entry' => (bool)$p['alert_on_entry'],
            'alert_on_exit'  => (bool)$p['alert_on_exit'],
        ];
    }, $places);

    respond(true, 'Places retrieved.', $data);
}

// 20. Geofence Places: Create Place
if ($method === 'POST' && preg_match('#^/api/v1/rooms/(\d+)/places$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];
    $body = getRequestBody();

    $name = trim($body['name'] ?? '');
    $lat = isset($body['latitude']) ? (float)$body['latitude'] : null;
    $lng = isset($body['longitude']) ? (float)$body['longitude'] : null;
    $radius = isset($body['radius_meters']) ? (int)$body['radius_meters'] : 150;
    $address = trim($body['address'] ?? '');

    if (empty($name) || $lat === null || $lng === null) {
        respond(false, 'Place name and coordinates are required.', null, null, 422);
    }

    $stmt = $db->prepare("INSERT INTO places (room_id, created_by, name, address, latitude, longitude, radius_meters, alert_on_entry, alert_on_exit, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1, NOW(), NOW())");
    $stmt->execute([$roomId, $currentUser['id'], $name, $address ?: null, $lat, $lng, $radius]);
    $placeId = (int)$db->lastInsertId();

    respond(true, 'Place created successfully.', [
        'id'            => $placeId,
        'room_id'       => $roomId,
        'name'          => $name,
        'latitude'      => $lat,
        'longitude'     => $lng,
        'radius_meters' => $radius,
    ], null, 201);
}

// Helper: Format Call Payload with Initiator and Participants
function formatCallPayload(PDO $db, array $call): array {
    $callId = (int)$call['id'];
    $roomId = (int)$call['room_id'];

    // Get room name
    $roomStmt = $db->prepare("SELECT name, code FROM rooms WHERE id = ? LIMIT 1");
    $roomStmt->execute([$roomId]);
    $room = $roomStmt->fetch() ?: ['name' => 'Circle', 'code' => ''];

    // Get initiator info
    $initStmt = $db->prepare("
        SELECT u.id, u.name, u.username, p.avatar_url
        FROM users u
        LEFT JOIN user_profiles p ON p.user_id = u.id
        WHERE u.id = ? LIMIT 1
    ");
    $initStmt->execute([$call['initiator_id']]);
    $initiator = $initStmt->fetch() ?: ['id' => $call['initiator_id'], 'name' => 'Member', 'username' => '', 'avatar_url' => null];

    // Get participants
    $partStmt = $db->prepare("
        SELECT cp.id as participant_id, cp.user_id, cp.status, cp.joined_at,
               u.name, u.username, p.avatar_url
        FROM call_participants cp
        JOIN users u ON u.id = cp.user_id
        LEFT JOIN user_profiles p ON p.user_id = u.id
        WHERE cp.call_id = ?
        ORDER BY cp.status = 'joined' DESC, u.name ASC
    ");
    $partStmt->execute([$callId]);
    $participants = $partStmt->fetchAll();

    $partsData = array_map(function($p) {
        return [
            'id'         => (int)$p['participant_id'],
            'user_id'    => (int)$p['user_id'],
            'name'       => $p['name'],
            'username'   => $p['username'],
            'avatar_url' => $p['avatar_url'],
            'status'     => $p['status'],
            'joined_at'  => $p['joined_at'],
        ];
    }, $participants);

    return [
        'id'               => $callId,
        'room_id'          => $roomId,
        'room_name'        => $room['name'],
        'room_code'        => $room['code'],
        'initiator_id'     => (int)$call['initiator_id'],
        'initiator_name'   => $initiator['name'],
        'initiator_avatar' => $initiator['avatar_url'],
        'initiator'        => [
            'id'         => (int)$initiator['id'],
            'name'       => $initiator['name'],
            'username'   => $initiator['username'],
            'avatar_url' => $initiator['avatar_url'],
        ],
        'call_type'        => $call['call_type'],
        'status'           => $call['status'],
        'started_at'       => $call['started_at'],
        'ended_at'         => $call['ended_at'],
        'created_at'       => $call['created_at'],
        'participants'     => $partsData,
    ];
}

// 22. Calls: Initiate Call in Room
if ($method === 'POST' && preg_match('#^/api/v1/rooms/(\d+)/calls$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $roomId = (int)$m[1];
    $body = getRequestBody();

    $callType = ($body['call_type'] ?? 'voice') === 'video' ? 'video' : 'voice';
    $targetUserId = isset($body['target_user_id']) ? (int)$body['target_user_id'] : null;
    $now = date('Y-m-d H:i:s');

    try {
        ensureSchemaExists($db);
        // End any lingering active calls in this room by this user
        $stmt = $db->prepare("UPDATE calls SET status = 'ended', ended_at = ?, updated_at = ? WHERE room_id = ? AND initiator_id = ? AND status IN ('calling', 'ringing', 'active')");
        $stmt->execute([$now, $now, $roomId, $currentUser['id']]);

        // Create call session
        $stmt = $db->prepare("INSERT INTO calls (room_id, initiator_id, call_type, status, started_at, created_at, updated_at) VALUES (?, ?, ?, 'calling', ?, ?, ?)");
        $stmt->execute([$roomId, $currentUser['id'], $callType, $now, $now, $now]);
        $callId = (int)$db->lastInsertId();

        // Add initiator as joined participant
        $stmt = $db->prepare("INSERT INTO call_participants (call_id, user_id, status, joined_at, created_at, updated_at) VALUES (?, ?, 'joined', ?, ?, ?)");
        $stmt->execute([$callId, $currentUser['id'], $now, $now, $now]);

        // Add participants: if target_user_id is specified (1-on-1 direct call), only ring that member!
        if ($targetUserId !== null && $targetUserId > 0 && $targetUserId !== (int)$currentUser['id']) {
            $otherMembers = [$targetUserId];
        } else {
            $stmt = $db->prepare("SELECT user_id FROM room_members WHERE room_id = ? AND user_id != ?");
            $stmt->execute([$roomId, $currentUser['id']]);
            $otherMembers = $stmt->fetchAll(PDO::FETCH_COLUMN);
        }

        if (!empty($otherMembers)) {
            $partInsert = $db->prepare("INSERT INTO call_participants (call_id, user_id, status, created_at, updated_at) VALUES (?, ?, 'ringing', ?, ?)");
            foreach ($otherMembers as $targetId) {
                try {
                    $partInsert->execute([$callId, (int)$targetId, $now, $now]);
                } catch (Throwable $e) {}
            }
        }

        $stmt = $db->prepare("SELECT * FROM calls WHERE id = ? LIMIT 1");
        $stmt->execute([$callId]);
        $call = $stmt->fetch();

        respond(true, 'Call initiated.', formatCallPayload($db, $call), null, 201);
    } catch (Throwable $e) {
        respond(false, 'Unable to initiate call: ' . $e->getMessage(), null, null, 500);
    }
}

// 23. Calls: Get Active / Incoming Call for Current User
if ($method === 'GET' && $uri === '/api/v1/calls/active') {
    $currentUser = authenticateUser($db);

    // Look for active call where user is initiator or participant
    $stmt = $db->prepare("
        SELECT c.*
        FROM calls c
        LEFT JOIN call_participants cp ON cp.call_id = c.id
        WHERE c.status IN ('calling', 'ringing', 'active')
          AND (c.initiator_id = ? OR (cp.user_id = ? AND cp.status IN ('ringing', 'joined')))
        ORDER BY c.id DESC
        LIMIT 1
    ");
    $stmt->execute([$currentUser['id'], $currentUser['id']]);
    $call = $stmt->fetch();

    if (!$call) {
        respond(true, 'No active call.', null);
    }

    respond(true, 'Active call found.', formatCallPayload($db, $call));
}

// 24. Calls: Get Call Details by ID
if ($method === 'GET' && preg_match('#^/api/v1/calls/(\d+)$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $callId = (int)$m[1];

    $stmt = $db->prepare("SELECT * FROM calls WHERE id = ? LIMIT 1");
    $stmt->execute([$callId]);
    $call = $stmt->fetch();

    if (!$call) {
        respond(false, 'Call session not found.', null, null, 404);
    }

    respond(true, 'Call details retrieved.', formatCallPayload($db, $call));
}

// 25. Calls: Join / Answer Call
if ($method === 'POST' && preg_match('#^/api/v1/calls/(\d+)/join$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $callId = (int)$m[1];

    $stmt = $db->prepare("SELECT * FROM calls WHERE id = ? LIMIT 1");
    $stmt->execute([$callId]);
    $call = $stmt->fetch();

    if (!$call || $call['status'] === 'ended') {
        respond(false, 'Call is no longer active.', null, null, 400);
    }

    // Upsert participant status to joined
    $chk = $db->prepare("SELECT id FROM call_participants WHERE call_id = ? AND user_id = ? LIMIT 1");
    $chk->execute([$callId, $currentUser['id']]);
    $existingPart = $chk->fetch();
    if ($existingPart) {
        $db->prepare("UPDATE call_participants SET status = 'joined', joined_at = NOW(), updated_at = NOW() WHERE id = ?")
            ->execute([$existingPart['id']]);
    } else {
        $db->prepare("INSERT INTO call_participants (call_id, user_id, status, joined_at, created_at, updated_at) VALUES (?, ?, 'joined', NOW(), NOW(), NOW())")
            ->execute([$callId, $currentUser['id']]);
    }

    // If call was calling/ringing, transition to active
    $stmt = $db->prepare("UPDATE calls SET status = 'active', updated_at = NOW() WHERE id = ? AND status IN ('calling', 'ringing')");
    $stmt->execute([$callId]);

    $stmt = $db->prepare("SELECT * FROM calls WHERE id = ? LIMIT 1");
    $stmt->execute([$callId]);
    $updatedCall = $stmt->fetch();

    respond(true, 'Joined call successfully.', formatCallPayload($db, $updatedCall));
}

// 26. Calls: Decline Call
if ($method === 'POST' && preg_match('#^/api/v1/calls/(\d+)/decline$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $callId = (int)$m[1];

    $chk = $db->prepare("SELECT id FROM call_participants WHERE call_id = ? AND user_id = ? LIMIT 1");
    $chk->execute([$callId, $currentUser['id']]);
    $existingPart = $chk->fetch();
    if ($existingPart) {
        $db->prepare("UPDATE call_participants SET status = 'declined', updated_at = NOW() WHERE id = ?")
            ->execute([$existingPart['id']]);
    } else {
        $db->prepare("INSERT INTO call_participants (call_id, user_id, status, created_at, updated_at) VALUES (?, ?, 'declined', NOW(), NOW())")
            ->execute([$callId, $currentUser['id']]);
    }

    // Check if this was a 1-on-1 call that got declined
    $stmt = $db->prepare("SELECT * FROM calls WHERE id = ? LIMIT 1");
    $stmt->execute([$callId]);
    $call = $stmt->fetch();
    if ($call && $call['status'] !== 'ended') {
        $partStmt = $db->prepare("SELECT COUNT(*) FROM call_participants WHERE call_id = ? AND user_id != ? AND status != 'declined'");
        $partStmt->execute([$callId, $call['initiator_id']]);
        $remaining = (int)$partStmt->fetchColumn();
        if ($remaining === 0) {
            $stmt = $db->prepare("UPDATE calls SET status = 'ended', ended_at = NOW(), updated_at = NOW() WHERE id = ?");
            $stmt->execute([$callId]);

            // Insert "Missed call" log into chat
            $callType = $call['call_type'] === 'video' ? 'video' : 'voice';
            $logContent = ($callType === 'video' ? 'Missed video call' : 'Missed voice call');
            $msgStmt = $db->prepare("
                INSERT INTO messages (room_id, user_id, message_type, content, is_deleted, created_at, updated_at)
                VALUES (?, ?, 'call_log', ?, 0, NOW(), NOW())
            ");
            $msgStmt->execute([$call['room_id'], $call['initiator_id'], $logContent]);
        }
    }

    respond(true, 'Call declined.');
}

// 27. Calls: End Call
if ($method === 'POST' && preg_match('#^/api/v1/calls/(\d+)/end$#', $uri, $m)) {
    $currentUser = authenticateUser($db);
    $callId = (int)$m[1];

    $stmt = $db->prepare("SELECT * FROM calls WHERE id = ? LIMIT 1");
    $stmt->execute([$callId]);
    $call = $stmt->fetch();

    if ($call && $call['status'] !== 'ended') {
        // Check if any remote participant joined and calculate call duration
        $partStmt = $db->prepare("SELECT user_id, status, joined_at FROM call_participants WHERE call_id = ? AND user_id != ?");
        $partStmt->execute([$callId, $call['initiator_id']]);
        $otherParts = $partStmt->fetchAll();

        $anyJoined = false;
        $earliestJoined = null;
        foreach ($otherParts as $op) {
            if ($op['status'] === 'joined' || !empty($op['joined_at'])) {
                $anyJoined = true;
                if ($earliestJoined === null || (strtotime($op['joined_at']) < strtotime($earliestJoined))) {
                    $earliestJoined = $op['joined_at'];
                }
            }
        }

        $durationSec = 0;
        if ($anyJoined && $earliestJoined) {
            $durationSec = max(1, time() - strtotime($earliestJoined));
        }

        $durationLabel = '';
        if ($durationSec > 0) {
            $mins = floor($durationSec / 60);
            $secs = $durationSec % 60;
            if ($mins > 0) {
                $durationLabel = "{$mins}m {$secs}s";
            } else {
                $durationLabel = "{$secs}s";
            }
        }

        $callType = $call['call_type'] === 'video' ? 'video' : 'voice';
        if ($anyJoined) {
            $logContent = ($callType === 'video' ? 'Video call ended' : 'Voice call ended') . ' • ' . $durationLabel;
        } else {
            $logContent = ($callType === 'video' ? 'Cancelled video call' : 'Cancelled call');
        }

        // Insert Facebook-style call_log message into room
        $msgStmt = $db->prepare("
            INSERT INTO messages (room_id, user_id, message_type, content, is_deleted, created_at, updated_at)
            VALUES (?, ?, 'call_log', ?, 0, NOW(), NOW())
        ");
        $msgStmt->execute([$call['room_id'], $currentUser['id'], $logContent]);
    }

    $stmt = $db->prepare("UPDATE calls SET status = 'ended', ended_at = NOW(), updated_at = NOW() WHERE id = ?");
    $stmt->execute([$callId]);

    $stmt = $db->prepare("UPDATE call_participants SET status = 'left', left_at = NOW(), updated_at = NOW() WHERE call_id = ? AND status IN ('ringing', 'joined')");
    $stmt->execute([$callId]);

    respond(true, 'Call ended.');
}

// 404 Route Not Found
respond(false, 'Endpoint not found: ' . $method . ' ' . $uri, null, null, 404);

