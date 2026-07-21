@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not available in PATH.
  echo Install Flutter, restart the terminal, then run this file again.
  pause
  exit /b 1
)

if not exist android (
  echo Generating Android and iOS platform folders...
  flutter create --platforms=android,ios --org com.marketai --project-name market_ai .
  if errorlevel 1 goto :failed
)

echo Getting Flutter packages...
flutter pub get
if errorlevel 1 goto :failed

echo Starting MarketAI...
flutter run
if errorlevel 1 goto :failed
exit /b 0

:failed
echo.
echo Setup or launch failed. Run "flutter doctor" and fix the reported environment issue.
pause
exit /b 1
