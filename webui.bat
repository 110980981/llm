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

:: RAG settings
:: Embedding model (default: all-MiniLM-L6-v2, too weak for Chinese)
set RAG_EMBEDDING_MODEL=BAAI/bge-m3
set RAG_EMBEDDING_MODEL_TRUST_REMOTE_CODE=true
set RAG_EMBEDDING_BATCH_SIZE=32

:: Chunking
set CHUNK_SIZE=3000
set CHUNK_OVERLAP=300

:: Retrieval
set RAG_TOP_K=30
set RAG_RELEVANCE_THRESHOLD=0.2

:: Hybrid search (keyword + semantic)
set ENABLE_RAG_HYBRID_SEARCH=true

:: Reranking (re-rank top results for precision)
set RAG_RERANKING_MODEL=BAAI/bge-reranker-v2-m3
set RAG_RERANKING_MODEL_TRUST_REMOTE_CODE=true
set RAG_TOP_K_RERANKER=10
set RAG_RERANKING_BATCH_SIZE=16

:: Web search (local SearXNG)
set ENABLE_WEB_SEARCH=true
set WEB_SEARCH_ENGINE=searxng
set SEARXNG_QUERY_URL=http://localhost:8889/search

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
