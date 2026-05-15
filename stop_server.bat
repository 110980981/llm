@echo off
title Stop llama.cpp Server

echo Stopping llama.cpp server...

:: Kill llama-server process by image name
taskkill /F /IM llama-server.exe >nul 2>&1

:: Also kill any process still holding port 11434
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :11434') do (
    if not "%%a"=="" taskkill /F /PID %%a >nul 2>&1
)

if errorlevel 1 (
    echo Server was not running.
) else (
    echo Stopped successfully.
)
