@echo off
echo Installing LunarAI Beauty Business Analysis...
echo.

where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: npm is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org
    pause
    exit /b 1
)

echo Installing dependencies...
call npm install

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Installation complete!
    echo.
    echo Next steps:
    echo 1. Copy .env.example to .env and configure your variables
    echo 2. Run: npm run dev
    echo 3. Open http://localhost:3000
    echo.
) else (
    echo.
    echo ✗ Installation failed. Please check the error messages above.
    echo.
)

pause
