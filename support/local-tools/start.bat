@echo off
setlocal
echo Starting LunarAI Beauty Business Analysis web app...
echo.

set "APP_DIR=%~dp0..\..\apps\bolt-vercel"
pushd "%APP_DIR%" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: cannot locate apps\bolt-vercel. Please run this script from within the repository.
    pause
    exit /b 1
)

echo Launching development server from %CD% ...
start "" http://localhost:3004
call npm run dev
set "DEV_EXIT=%ERRORLEVEL%"

if %DEV_EXIT% NEQ 0 (
    echo.
    echo Development server exited with code %DEV_EXIT%.
    echo.
)

popd >nul
pause