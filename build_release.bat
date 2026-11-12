@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
set "JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8 -Duser.language=en -Duser.country=US"

rem Full release build script for Angle Calculator.
rem Keep this file ASCII-only so cmd.exe can run it safely by double click.

echo.
echo ============================================
echo Angle Calculator - Release Build
echo ============================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Flutter was not found in PATH.
    echo Please install Flutter or add Flutter bin directory to PATH.
    echo.
    pause
    exit /b 1
)

set "currentVersion="
for /f "tokens=2" %%A in ('findstr /b /c:"version:" pubspec.yaml') do (
    set "currentVersion=%%A"
)

if not defined currentVersion (
    echo [ERROR] Could not read version from pubspec.yaml.
    echo Expected line format: version: 1.0.4+4
    echo.
    pause
    exit /b 1
)

for /f "tokens=1,2 delims=+" %%A in ("!currentVersion!") do (
    set "currentName=%%A"
    set "currentCode=%%B"
)

if not defined currentCode (
    set "currentCode=0"
)

echo Current version: !currentVersion!
echo.
echo Enter a new app version, or press Enter to keep the current version.
echo Examples:
echo   1.0.5      - use versionName 1.0.5 and auto-increment build number
echo   1.0.5+12   - use exact version and build number
echo.
set "requestedVersion="
set /p "requestedVersion=New version: "
for /f "usebackq delims=" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "'!requestedVersion!'.Trim()"`) do (
    set "requestedVersion=%%A"
)

if "!requestedVersion!"=="" (
    set "finalVersion=!currentVersion!"
    set "finalName=!currentName!"
    set "finalCode=!currentCode!"
) else (
    set "requestedName="
    set "requestedCode="
    for /f "tokens=1,2 delims=+" %%A in ("!requestedVersion!") do (
        set "requestedName=%%A"
        set "requestedCode=%%B"
    )

    if "!requestedName!"=="" (
        echo.
        echo [ERROR] Version name cannot be empty.
        echo.
        pause
        exit /b 1
    )

    echo !requestedName!| findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
    if errorlevel 1 (
        echo.
        echo [ERROR] Invalid version name: !requestedName!
        echo Expected format: 1.0.5 or 1.0.5+12
        echo.
        pause
        exit /b 1
    )

    if not "!requestedCode!"=="" (
        echo !requestedCode!| findstr /r "^[0-9][0-9]*$" >nul
        if errorlevel 1 (
            echo.
            echo [ERROR] Invalid build number: !requestedCode!
            echo Expected format: 1.0.5+12
            echo.
            pause
            exit /b 1
        )
    )

    if not "!requestedCode!"=="" (
        set "finalName=!requestedName!"
        set "finalCode=!requestedCode!"
        set "finalVersion=!requestedName!+!requestedCode!"
    ) else (
        set /a nextCode=!currentCode! + 1
        set "finalName=!requestedName!"
        set "finalCode=!nextCode!"
        set "finalVersion=!requestedName!+!nextCode!"
    )
)

echo.
echo Build version: !finalVersion!
echo.

if not "!finalVersion!"=="!currentVersion!" (
    echo Updating pubspec.yaml and android\local.properties...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = 'pubspec.yaml'; $content = Get-Content -Raw -Encoding UTF8 $path; $content = $content -replace '(?m)^version:\s*.+$', 'version: !finalVersion!'; $utf8NoBom = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText((Resolve-Path $path), $content, $utf8NoBom)"
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to update pubspec.yaml.
        echo.
        pause
        exit /b 1
    )

    if exist "android\local.properties" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = 'android\local.properties'; $content = Get-Content -Raw -Encoding UTF8 $path; if ($content -match '(?m)^flutter\.versionName=') { $content = $content -replace '(?m)^flutter\.versionName=.*$', 'flutter.versionName=!finalName!' } else { $content += \"`r`nflutter.versionName=!finalName!\" }; if ($content -match '(?m)^flutter\.versionCode=') { $content = $content -replace '(?m)^flutter\.versionCode=.*$', 'flutter.versionCode=!finalCode!' } else { $content += \"`r`nflutter.versionCode=!finalCode!\" }; $ascii = [System.Text.Encoding]::ASCII; [System.IO.File]::WriteAllText((Resolve-Path $path), $content, $ascii)"
        if errorlevel 1 (
            echo.
            echo [ERROR] Failed to update android\local.properties.
            echo.
            pause
            exit /b 1
        )
    )
) else (
    echo Keeping existing version.
)

echo.
echo [1/4] Cleaning old build files...
call flutter clean
if errorlevel 1 (
    echo.
    echo [ERROR] flutter clean failed.
    echo.
    pause
    exit /b 1
)

echo.
echo [2/4] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo.
    echo [ERROR] flutter pub get failed.
    echo.
    pause
    exit /b 1
)

echo.
echo [3/4] Running analyzer...
call flutter analyze
if errorlevel 1 (
    echo.
    echo [WARNING] flutter analyze reported issues. Build will continue.
)

echo.
echo [4/4] Building release APK...
call flutter build apk --release
if errorlevel 1 (
    echo.
    echo [ERROR] Release build failed.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo [SUCCESS] Release APK build completed.
echo ============================================
echo.
echo Output: build\app\outputs\flutter-apk\app-release.apk
echo.

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do (
        set "size=%%~zA"
        set /a sizeMB=!size! / 1024 / 1024
        echo APK size: !sizeMB! MB
    )
) else (
    echo [WARNING] APK file was not found at the expected path.
)

echo.
echo Press any key to exit...
pause >nul
endlocal
