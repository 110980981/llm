#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
UV="$HOME/.local/bin/uv"

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

# Check/install open-webui
if ! pip show open-webui >/dev/null 2>&1; then
    echo "Installing Open WebUI - this may take a few minutes..."
    UV_LINK_MODE=copy "$UV" pip install --python "$VENV_DIR" open-webui
    echo
fi

# Configure OpenAI-compatible endpoint to point at llama.cpp
export OPENAI_API_BASE_URLS=http://127.0.0.1:11434/v1
export OPENAI_API_KEYS=not-needed
export HF_ENDPOINT=https://hf-mirror.com

# Web search (local SearXNG)
export ENABLE_WEB_SEARCH=true
export WEB_SEARCH_ENGINE=searxng
export SEARXNG_QUERY_URL=http://localhost:8889/search

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
