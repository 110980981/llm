@echo off
title Stop Open WebUI

set PID_FILE=%~dp0webui.pid

if not exist "%PID_FILE%" (
    echo Open WebUI is not running (no PID file found).
    exit /b 0
)

set /p PID=<"%PID_FILE%"

echo Stopping Open WebUI (PID: %PID%)...
taskkill /F /PID %PID% >nul 2>&1

if errorlevel 1 (
    echo Process already exited.
) else (
    echo Stopped successfully.
)

del "%PID_FILE%"
