@echo off
REM Launches Install-Dlls.ps1 elevated, bypassing execution policy for this run only.
setlocal
set "SCRIPT=%~dp0Install-Dlls.ps1"

REM Self-elevate if not already admin.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
echo.
pause
