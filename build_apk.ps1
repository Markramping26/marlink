$javaHome = "C:\Users\juneil\jdk-17\jdk-17.0.10+7"
$androidHome = "C:\Users\juneil\AppData\Local\Android\Sdk"
$flutterBin = "C:\Users\juneil\flutter\bin"

$env:JAVA_HOME = $javaHome
$env:ANDROID_HOME = $androidHome
$env:PATH = "$javaHome\bin;$androidHome\platform-tools;$androidHome\cmdline-tools\latest\bin;$flutterBin;$env:PATH"

# Configure Flutter with Android SDK and JDK paths
& "$flutterBin\flutter.bat" config --android-sdk $androidHome
& "$flutterBin\flutter.bat" config --jdk-dir $javaHome

Write-Host "=== FLUTTER DOCTOR STATUS ==="
& "$flutterBin\flutter.bat" doctor

Write-Host "=== STARTING APK BUILD ==="
Set-Location "c:\AndriodStudioProjects\marlink\marlink_app"
& "$flutterBin\flutter.bat" pub get
& "$flutterBin\flutter.bat" build apk --debug

if (Test-Path "c:\AndriodStudioProjects\marlink\marlink_app\build\app\outputs\flutter-apk\app-debug.apk") {
    $apkPath = "c:\AndriodStudioProjects\marlink\marlink_app\build\app\outputs\flutter-apk\app-debug.apk"
    $sizeMb = [math]::Round(((Get-Item $apkPath).Length / 1MB), 2)
    $targetApk = "c:\AndriodStudioProjects\marlink\MarLink.apk"
    Copy-Item -Path $apkPath -Destination $targetApk -Force
    Write-Host "=== SUCCESS: APK BUILT & COPIED SUCCESSFULLY! ==="
    Write-Host "Root APK: $targetApk"
    Write-Host "APK File Size: $sizeMb MB"
} else {
    Write-Host "=== APK build completed. Checking output directory ==="
    Get-ChildItem "c:\AndriodStudioProjects\marlink\marlink_app\build\app\outputs" -Recurse -Filter *.apk
}
