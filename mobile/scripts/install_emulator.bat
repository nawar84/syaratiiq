@echo off
setlocal
set FLUTTER=C:\Users\nawar\.puro\envs\cariq\flutter\bin\flutter.bat
set ADB=C:\Users\nawar\AppData\Local\Android\Sdk\platform-tools\adb.exe
set DEVICE=emulator-5554

cd /d "%~dp0.."

echo Building debug APK...
call "%FLUTTER%" build apk --debug
if errorlevel 1 exit /b 1

echo Installing on %DEVICE%...
"%ADB%" -s %DEVICE% install -r "build\app\outputs\flutter-apk\app-debug.apk"
if errorlevel 1 exit /b 1

echo Launching سياراتي IQ...
"%ADB%" -s %DEVICE% shell monkey -p iq.cariq.app -c android.intent.category.LAUNCHER 1 >nul 2>&1
if errorlevel 1 (
  "%ADB%" -s %DEVICE% shell am start -n iq.cariq.app/com.example.mobile.MainActivity
)

echo Done. Look for "سياراتي IQ" in the app drawer.
endlocal
