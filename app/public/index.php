<?php
// Set content type to JSON
header('Content-Type: application/json');

$apiKeyHeader = $_SERVER['HTTP_X_API_KEY'] ?? null;
$expectedApiKey = getenv('API_KEY') ?: 'somethingverysecure';

// Get the requested URI (e.g., /api or /health)
$request = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// API key check
$protectedPaths = ['/api'];
if (in_array($request, $protectedPaths) && $apiKeyHeader !== $expectedApiKey) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

function log_request($path) {
    $method = $_SERVER['REQUEST_METHOD'];
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';
    $query = $_SERVER['QUERY_STRING'] ?? '';

    $logEntry = [
        "timestamp" => gmdate("Y-m-d\TH:i:s\Z"),
        "level"     => "info",
        "service"   => getenv('SERVICE_NAME') ?: 'php-app',
        "message"   => "Incoming request",
        "context"   => [
            "method" => $method,
            "path" => $path,
            "query" => $query,
            "ip" => $ip,
            "user_agent" => $userAgent
        ]
    ];

    // // Log to stdout / console (works with Docker / CloudWatch)
    // echo json_encode($logEntry) . PHP_EOL;
    // Write log to stderr instead of HTTP response
    file_put_contents('php://stderr', json_encode($logEntry) . PHP_EOL);
}

log_request($request);

switch ($request) {
    case '/health':
        // Health check endpoint
        log_json("info", "API request received", ["path" => $_SERVER['REQUEST_URI']]);
        echo json_encode(['status' => 'OK', 'timestamp' => time()]);
        break;

    case '/api':
        // Main API endpoint
        echo json_encode([
            'message' => 'Welcome to the API',
            'data' => ['id' => 1, 'name' => 'Sample Data']
        ]);
        break;

    default:
        // Handle 404 - Not Found
        http_response_code(404);
        echo json_encode(['error' => 'Route not found']);
        break;
}
?>
