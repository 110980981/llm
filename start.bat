@echo off
title LLM llama.cpp

:: Bootstrap: auto-download external dependencies (llama.cpp)
echo [0/3] Checking dependencies...
python "%~dp0bootstrap.py"
if errorlevel 1 (
    echo Failed to setup llama.cpp. Check your internet connection.
    pause
    exit /b 1
)

:: Cleanup from previous runs
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

:: Start llama.cpp server (background, same console)
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

:: Wait for model to load
echo [2/2] Loading model...
python "%~dp0wait.py"

echo.
echo ============================================
echo  Server ready at http://127.0.0.1:11434/v1
echo ============================================

:: Start Open WebUI
pip show open-webui >nul 2>&1
if errorlevel 1 (
    echo Installing Open WebUI - this may take a few minutes...
    pip install --default-timeout=120 open-webui
    echo.
)

set OPENAI_API_BASE_URLS=http://127.0.0.1:11434/v1
set OPENAI_API_KEYS=not-needed
set HF_ENDPOINT=https://hf-mirror.com

:: RAG settings — bge-m3 embedding + hybrid search + reranking
set RAG_EMBEDDING_MODEL=BAAI/bge-m3
set RAG_EMBEDDING_MODEL_TRUST_REMOTE_CODE=true
set RAG_EMBEDDING_MODEL_AUTO_UPDATE=false
set RAG_EMBEDDING_BATCH_SIZE=32
set SENTENCE_TRANSFORMERS_BACKEND=torch
set CHUNK_SIZE=3000
set CHUNK_OVERLAP=300
set RAG_TOP_K=30
set RAG_RELEVANCE_THRESHOLD=0.2
set ENABLE_RAG_HYBRID_SEARCH=true
set RAG_RERANKING_MODEL=BAAI/bge-reranker-v2-m3
set RAG_RERANKING_MODEL_TRUST_REMOTE_CODE=true
set RAG_TOP_K_RERANKER=10
set RAG_RERANKING_BATCH_SIZE=16

:: Web search (local SearXNG)
set ENABLE_WEB_SEARCH=true
set WEB_SEARCH_ENGINE=searxng
set SEARXNG_QUERY_URL=http://localhost:8888/search

:: Pre-load embedding model (avoids download timeout during Open WebUI startup)
echo [3/3] Loading embedding model...
python "%~dp0warm_embedding.py"
if errorlevel 1 (
    echo Warning: embedding model failed to load, RAG may not work.
)

echo Starting Open WebUI at http://localhost:8080 ...
start "" http://localhost:8080
echo.
echo Close this terminal window to stop everything.
echo.

open-webui serve

:: Cleanup when webui exits
taskkill /F /IM llama-server.exe >nul 2>&1
