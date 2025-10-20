@echo off
setlocal
echo Installing LunarAI Beauty Business Analysis web app...
echo.

where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: npm is not installed or not in PATH.
    echo Please install Node.js from https://nodejs.org.
    pause
    exit /b 1
)

set "APP_DIR=%~dp0..\..\apps\bolt-vercel"
pushd "%APP_DIR%" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: cannot locate apps\bolt-vercel. Please run this script from within the repository.
    pause
    exit /b 1
)

echo Installing dependencies in %CD% ...
call npm install
set "INSTALL_EXIT=%ERRORLEVEL%"

if %INSTALL_EXIT% EQU 0 (
    echo.
    echo Installation complete!
    echo.
    echo Next steps:
    echo 1. Copy .env.example to .env.local or run create-env.ps1.
    echo 2. Run: npm run dev
    echo 3. Open http://localhost:3004
    echo.
) else (
    echo.
    echo Installation failed. Please review the log above.
    echo.
)

popd >nul
pause