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

:: Web search
set ENABLE_WEB_SEARCH=true
set WEB_SEARCH_ENGINE=brave
set SEARXNG_QUERY_URL=https://searx.si/search
set SERPER_API_KEY=6160279de21992120478ef6afafdc74b01594b64
set BRAVE_SEARCH_API_KEY=BSAIAWmFnzCa0dnSTWARR65WUPUu2EN

echo Starting Open WebUI...
echo.
echo Open http://localhost:8080 in your browser.
echo.
echo First-time setup:
echo   1. Register an admin account
echo   2. The llama.cpp connection is auto-configured via OPENAI_BASE_URL
echo.
echo Press Ctrl+C to stop.
echo.
open-webui serve
