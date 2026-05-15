@echo off
title Open WebUI

:: Check/install open-webui
pip show open-webui >nul 2>&1
if errorlevel 1 (
    echo Installing Open WebUI - this may take a few minutes...
    pip install --default-timeout=120 open-webui
    echo.
)

:: Configure OpenAI-compatible endpoint to point at llama.cpp
set OPENAI_API_BASE_URLS=http://127.0.0.1:11434/v1
set OPENAI_API_KEYS=not-needed
set HF_ENDPOINT=https://hf-mirror.com

:: RAG settings — bge-m3 embedding + hybrid search + reranking
set RAG_EMBEDDING_MODEL=BAAI/bge-m3
set RAG_EMBEDDING_MODEL_TRUST_REMOTE_CODE=true
set RAG_EMBEDDING_MODEL_AUTO_UPDATE=false
set RAG_EMBEDDING_BATCH_SIZE=32
set SENTENCE_TRANSFORMERS_BACKEND=torch
set CHUNK_SIZE=1000
set CHUNK_OVERLAP=200
set RAG_TOP_K=10
set RAG_RELEVANCE_THRESHOLD=0.2
set ENABLE_RAG_HYBRID_SEARCH=true
set RAG_RERANKING_MODEL=BAAI/bge-reranker-v2-m3
set RAG_RERANKING_MODEL_TRUST_REMOTE_CODE=true
set RAG_TOP_K_RERANKER=10
set RAG_RERANKING_BATCH_SIZE=16
set RAG_SYSTEM_CONTEXT=true
set SENTENCE_TRANSFORMERS_BACKEND=torch

:: Web search (local SearXNG)
set ENABLE_WEB_SEARCH=true
set WEB_SEARCH_ENGINE=searxng
set SEARXNG_QUERY_URL=http://localhost:8888/search

:: Launch Open WebUI in background (silent, no console window)
echo Starting Open WebUI in background...
powershell -NoProfile -Command "$p = Start-Process -PassThru -WindowStyle Hidden -FilePath 'open-webui' -ArgumentList 'serve'; $p.Id | Out-File -Encoding ascii -FilePath '%~dp0webui.pid'"

if not exist "%~dp0webui.pid" (
    echo Failed to start Open WebUI.
    pause
    exit /b 1
)

set /p PID=<"%~dp0webui.pid"
echo Open WebUI started (PID: %PID%).
echo.
echo Open http://localhost:8080 in your browser.
echo First-time setup:
echo   1. Register an admin account
echo   2. The llama.cpp connection is auto-configured via OPENAI_BASE_URL
echo.
echo To stop: run stop_webui.bat
echo.
