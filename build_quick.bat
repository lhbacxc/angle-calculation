@echo off
setlocal EnableExtensions
chcp 65001 >nul
set "JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8 -Duser.language=en -Duser.country=US"

rem Quick release build script for Angle Calculator.
rem ASCII-only to avoid encoding issues on double click.

echo.
echo ============================================
echo Angle Calculator - Quick Release Build
echo ============================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Flutter was not found in PATH.
    echo.
    pause
    exit /b 1
)

echo Building release APK...
call flutter build apk --release
if errorlevel 1 (
    echo.
    echo [ERROR] Build failed.
    echo.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] APK built successfully.
echo Output: build\app\outputs\flutter-apk\app-release.apk
echo.
pause
endlocal
