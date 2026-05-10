@echo off
title llama.cpp Server

:: Kill existing llama-server and free ports
taskkill /F /IM llama-server.exe >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :11434') do (
    if not "%%a"=="" taskkill /F /PID %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul

:: Model selection
cd /d "%~dp0"
python select_model.py > "%TEMP%\llm_sel.txt"
set /p MODEL_LINE=<"%TEMP%\llm_sel.txt"
for /f "delims=| tokens=1,2,3" %%i in ("%MODEL_LINE%") do (
    set GGUF_PATH=%%i
    set MODEL_NAME=%%j
    set MOE_ARGS=%%k
)
del "%TEMP%\llm_sel.txt"

echo.
echo Starting: %MODEL_NAME%
echo.

:: Start llama-server (background)
echo [1/2] Starting llama.cpp server...
set GPU_LAYERS=99
set SLOTS=1
set CTX=16384
if /i "%MODEL_NAME%"=="qwen3-8b" set GPU_LAYERS=24
if /i "%MODEL_NAME%"=="qwen3.6-35b" set SLOTS=1
if /i "%MODEL_NAME%"=="qwen3.6-35b" set CTX=16384
if /i "%MODEL_NAME%"=="qwen3.6-35b" set GPU_LAYERS=0
set BATCH=1024
set THREADS=8
if /i "%MODEL_NAME%"=="qwen3.6-35b" set BATCH=4096
if /i "%MODEL_NAME%"=="qwen3.6-35b" set THREADS=14
start /B "" "%~dp0llama\llama-server.exe" -m "%GGUF_PATH%" --host 127.0.0.1 --port 11434 -ngl %GPU_LAYERS% %MOE_ARGS% -fa on -ctk q8_0 -ctv q8_0 -c %CTX% -np %SLOTS% -t %THREADS% -tb %THREADS% -b %BATCH% -ub %BATCH% --temp 0.7 --repeat-penalty 1.1 --top-k 40 --cache-reuse 256 --jinja > "%TEMP%\llama_server.log" 2>&1

:: Wait for ready
echo [2/2] Loading model...
python "%~dp0wait.py"

echo.
echo ============================================
echo  Server ready at http://127.0.0.1:11434/v1
echo  Run start.bat to launch Open WebUI.
echo  Use stop.bat to stop the server.
echo ============================================
