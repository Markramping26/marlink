$zipUrl = "https://download.visualstudio.microsoft.com/download/pr/e923d809-9553-4b01-87d4-b201c682b08d/c60353c18a0659148df842ecbf1710f1/microsoft-jdk-17.0.10-windows-x64.zip"
$zipPath = "C:\Users\juneil\Downloads\jdk17.zip"
$targetDir = "C:\Users\juneil\jdk-17"

Write-Host "=== Step 1: Downloading Microsoft OpenJDK 17 (~170 MB) ==="
& curl.exe -L -C - -o $zipPath $zipUrl

Write-Host "=== Step 2: Extracting to $targetDir ==="
if (Test-Path $targetDir) { Remove-Item $targetDir -Recurse -Force }
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
& tar.exe -xf $zipPath -C $targetDir

Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

# Find jdk folder inside targetDir
$jdkSub = Get-ChildItem -Path $targetDir -Directory | Select-Object -First 1
if ($jdkSub) {
    $javaHome = $jdkSub.FullName
} else {
    $javaHome = $targetDir
}

$javaBin = "$javaHome\bin"

# Set environment variables
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "User")
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$javaBin*") {
    $newUserPath = "$userPath;$javaBin"
    [System.Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")
}

$env:JAVA_HOME = $javaHome
$env:PATH = "$javaBin;$env:PATH"

Write-Host "=== Step 3: Verifying Java ==="
& "$javaBin\java.exe" -version
Write-Host "=== JAVA 17 SETUP COMPLETED ==="
