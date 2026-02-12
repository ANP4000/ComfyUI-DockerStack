@echo off
setlocal
echo =================================
echo  ComfyUI First-Time Content Setup
echo =================================
echo.
echo This script will download all necessary custom nodes and models.
echo Please ensure Docker Desktop is running.
echo It requires modern PowerShell (pwsh.exe) to be installed.
echo.

REM This command uses "pwsh.exe" to avoid issues with the older "powershell.exe"
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0\setup.ps1"

echo.
echo =================================
echo  Setup Complete!
echo =================================
pause
endlocal