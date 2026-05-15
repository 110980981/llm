@echo off
title Stop Open WebUI

:: Try PID file first (webui.bat launch path)
set PID_FILE=%~dp0webui.pid
if exist "%PID_FILE%" (
    set /p PID=<"%PID_FILE%"
    taskkill /F /PID %PID% >nul 2>&1
    del "%PID_FILE%"
)

:: Also kill by image name (start.bat launch path)
taskkill /F /IM open-webui.exe >nul 2>&1

echo Done.
