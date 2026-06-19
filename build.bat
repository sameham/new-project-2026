@echo off
REM ╔══════════════════════════════════════╗
REM ║  elmahdi_travel_suite — Build Script ║
REM ╚══════════════════════════════════════╝

echo 🚀 Building elmahdi_travel_suite...

echo.
echo 📦 Step 1: Installing dependencies...
flutter pub get

echo.
echo ⚙️  Step 2: Running code generation...
flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo ✅ Build ready! Run with: flutter run
pause
