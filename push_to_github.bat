@echo off
title MarLink GitHub Auto-Push
color 0A
echo ========================================================
echo   MarLink Cloud Deployment: Pushing to GitHub
echo   Repository: https://github.com/Markramping26/marlink
echo ========================================================
echo.
set "PATH=C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\Users\juneil\git\cmd;C:\Users\juneil\git\mingw64\bin;%PATH%"
cd /d c:\AndroidStudioProjects\marlink

echo Staging all updated files...
git add .

echo Committing updates...
git commit -m "Fix: Seed Loleng on Render database, fix 401 error message, and remove top server pill"

echo Pushing code to GitHub main branch...
git push -u origin main

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================================
    echo   [SUCCESS] Naka-push na sa GitHub ang MarLink!
    echo   Awtomatikong magbi-build at deploy ang Render cloud.
    echo ========================================================
    echo.
) else (
    echo.
    echo ========================================================
    echo   May kailangang i-authorize sa GitHub o may error sa push.
    echo ========================================================
    echo.
)

pause
