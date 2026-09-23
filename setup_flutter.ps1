$zipUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.5-stable.zip"
$zipPath = "C:\Users\juneil\Downloads\flutter_download.zip"
$extractPath = "C:\Users\juneil"
$flutterDir = "C:\Users\juneil\flutter"

Write-Host "=== Step 1: Downloading Flutter SDK (~1.1 GB) ==="
# Use curl.exe for high-speed download with resume support
& curl.exe -L -C - -o $zipPath $zipUrl

if (!(Test-Path $zipPath)) {
    Write-Error "Download failed: $zipPath not found."
    exit 1
}

Write-Host "=== Step 2: Extracting Flutter to $flutterDir ==="
# Use tar.exe or Expand-Archive (tar.exe is much faster in Windows 10/11)
if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
    & tar.exe -xf $zipPath -C $extractPath
} else {
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
}

$flutterBin = "$flutterDir\bin"
$flutterBat = "$flutterBin\flutter.bat"

if (Test-Path $flutterBat) {
    Write-Host "=== Step 3: Flutter extracted successfully! ==="
    
    # Add flutter bin to User PATH
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$flutterBin*") {
        $newUserPath = "$userPath;$flutterBin"
        [System.Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")
        Write-Host "Added $flutterBin to User PATH."
    }
    
    # Add to current session PATH
    $env:PATH = "$flutterBin;$env:PATH"
    
    # Clean up zip
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "Temporary zip file removed."
    
    Write-Host "=== Step 4: Configuring Flutter ==="
    & $flutterBat config --no-analytics
    & $flutterBat --version
    
    Write-Host "=== FLUTTER SETUP COMPLETED ==="
} else {
    Write-Error "Extraction failed. C:\flutter\bin\flutter.bat was not found."
    exit 1
}
