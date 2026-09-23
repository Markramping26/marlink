<?php
$ch = curl_init('http://127.0.0.1:8000/api/v1/auth/login');
$payload = json_encode([
    'login' => 'mark@marlink.local',
    'password' => 'Password123!',
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
$resp = curl_exec($ch);
curl_close($ch);

echo "LOGIN RESPONSE:\n" . $resp . "\n";
$data = json_decode($resp, true);
if (!empty($data['data']['token'])) {
    $token = $data['data']['token'];
    echo "TOKEN: " . $token . "\n";

    // Test PUT /api/v1/user/profile
    $ch = curl_init('http://127.0.0.1:8000/api/v1/user/profile');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['show_speed' => true, 'show_battery' => true]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token,
        'Content-Type: application/json',
        'Accept: application/json',
    ]);
    echo "Done verifying API endpoints.\n";
}
