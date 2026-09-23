$sdkDir = "C:\Users\juneil\AppData\Local\Android\Sdk"
$cmdlineDir = "$sdkDir\cmdline-tools"
$latestDir = "$cmdlineDir\latest"
$zipUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$zipPath = "C:\Users\juneil\Downloads\cmdline-tools.zip"

$javaHome = "C:\Users\juneil\jdk-17\jdk-17.0.10+7"
$env:JAVA_HOME = $javaHome
$env:PATH = "$javaHome\bin;C:\Users\juneil\flutter\bin;$env:PATH"

Write-Host "=== Setting up Android SDK Directory ==="
New-Item -ItemType Directory -Path $cmdlineDir -Force | Out-Null

Write-Host "=== Downloading Android Command-Line Tools (~150 MB) ==="
& curl.exe -L -C - -o $zipPath $zipUrl

Write-Host "=== Extracting Command-Line Tools ==="
& tar.exe -xf $zipPath -C $cmdlineDir

if (Test-Path "$cmdlineDir\cmdline-tools") {
    if (Test-Path $latestDir) { Remove-Item $latestDir -Recurse -Force }
    Rename-Item "$cmdlineDir\cmdline-tools" "latest"
}

Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

# Set Environment Variables
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkDir, "User")
$env:ANDROID_HOME = $sdkDir

# Tell Flutter where Android SDK & Java are
& "C:\Users\juneil\flutter\bin\flutter.bat" config --android-sdk $sdkDir
& "C:\Users\juneil\flutter\bin\flutter.bat" config --jdk-dir $javaHome

Write-Host "=== Installing Android Platform 34 and Build-Tools ==="
$sdkManager = "$latestDir\bin\sdkmanager.bat"

# Automatically accept licenses and install components
& cmd.exe /c "echo y| `"$sdkManager`" --licenses"
& cmd.exe /c "`"$sdkManager`" `"platform-tools`" `"platforms;android-34`" `"build-tools;34.0.0`""

# Accept flutter android licenses
& cmd.exe /c "echo y| `"C:\Users\juneil\flutter\bin\flutter.bat`" doctor --android-licenses"

Write-Host "=== Android SDK Setup Complete! ==="
