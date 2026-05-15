#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
UV="$HOME/.local/bin/uv"

# Use copy mode for all uv operations (hardlinks fail under proot)
export UV_LINK_MODE=copy

if [ ! -f "$UV" ]; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    UV="$HOME/.local/bin/uv"
fi

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "Creating Python virtual environment (3.12)..."
    "$UV" venv --python 3.12 "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Check/install open-webui (use import check instead of pip — venv may not have pip)
if ! python -c "import open_webui" 2>/dev/null; then
    echo "Installing Open WebUI - this may take a few minutes..."
    UV_LINK_MODE=copy "$UV" pip install --python "$VENV_DIR" open-webui
    echo
fi

# Configure OpenAI-compatible endpoint to point at llama.cpp
export OPENAI_API_BASE_URLS=http://127.0.0.1:11434/v1
export OPENAI_API_KEYS=not-needed
export HF_ENDPOINT=https://hf-mirror.com

# RAG settings — lightweight embedding + hybrid search + reranking
export RAG_EMBEDDING_MODEL=BAAI/bge-base-zh-v1.5
export RAG_EMBEDDING_MODEL_TRUST_REMOTE_CODE=true
export RAG_EMBEDDING_MODEL_AUTO_UPDATE=false
export RAG_EMBEDDING_BATCH_SIZE=32
export SENTENCE_TRANSFORMERS_BACKEND=torch

# Chunking
export CHUNK_SIZE=1000
export CHUNK_OVERLAP=200

# Retrieval
export RAG_TOP_K=10
export RAG_RELEVANCE_THRESHOLD=0.2

# Hybrid search (keyword + semantic)
export ENABLE_RAG_HYBRID_SEARCH=true

# Reranking (re-rank top results for precision)
export RAG_RERANKING_MODEL=BAAI/bge-reranker-v2-m3
export RAG_RERANKING_MODEL_TRUST_REMOTE_CODE=true
export RAG_TOP_K_RERANKER=10
export RAG_RERANKING_BATCH_SIZE=16
export RAG_SYSTEM_CONTEXT=true

# Pre-load embedding model (avoids download timeout during startup)
echo "Loading embedding model..."
python3 "$SCRIPT_DIR/warm_embedding.py" || echo "Warning: embedding model pre-load failed"

# Web search (local SearXNG)
export ENABLE_WEB_SEARCH=true
export WEB_SEARCH_ENGINE=searxng
export SEARXNG_QUERY_URL=http://localhost:8888/search

echo "Starting Open WebUI..."
echo
echo "Open http://localhost:8080 in your browser."
echo
echo "First-time setup:"
echo "  1. Register an admin account"
echo "  2. The llama.cpp connection is auto-configured via OPENAI_BASE_URL"
echo
echo "Press Ctrl+C to stop."
echo

open-webui serve
