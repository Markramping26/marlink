<?php
// Script to locate latest Flutter SDK and download it
$json = file_get_contents('https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json');
if (!$json) {
    die("Failed to fetch flutter releases json\n");
}
$data = json_decode($json, true);
$currentStableHash = $data['current_release']['stable'];
$archive = '';
$version = '';
foreach ($data['releases'] as $rel) {
    if ($rel['hash'] === $currentStableHash) {
        $archive = $rel['archive'];
        $version = $rel['version'];
        break;
    }
}

$url = $data['base_url'] . '/' . $archive;
echo "LATEST_VERSION: " . $version . "\n";
echo "DOWNLOAD_URL: " . $url . "\n";
