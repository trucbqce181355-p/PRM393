@echo off
node "%~dp0start-auth.js"
if errorlevel 1 exit /b 1
cd /d "%~dp0"
flutter run -d windows --dart-define-from-file=supabase.env.json
