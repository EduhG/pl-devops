<?php
// Set content type to JSON
header('Content-Type: application/json');

$apiKeyHeader = $_SERVER['HTTP_X_API_KEY'] ?? null;
$expectedApiKey = getenv('API_KEY') ?: 'somethingverysecure';

// Get the requested URI (e.g., /api or /health)
$request = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// API key check
$protectedPaths = ['/api', '/health'];
if (in_array($request, $protectedPaths) && $apiKeyHeader !== $expectedApiKey) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

switch ($request) {
    case '/health':
        // Health check endpoint
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
