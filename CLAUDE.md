# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

本地部署 LLM（通过 llama.cpp），前端使用 Open WebUI。所有外部依赖（llama.cpp、GGUF 模型）均在首次启动时自动下载。

## Architecture

```
llm/
├── frontend/
│   └── cli.py             # 交互式 CLI 客户端（备用）
├── llama/                 # 由 bootstrap.py 自动生成
│   └── llama-server.exe   # llama.cpp 服务器（自动下载，CUDA/CPU）
├── models.json            # 模型配置（唯一数据源，含下载 URL）
├── select_model.py        # 模型选择 + 自动下载
├── bootstrap.py           # 自动下载 llama.cpp（版本检测 + CUDA 检测）
├── start.bat              # 一键启动（唯一入口）
├── cli.bat                # 启动 CLI（备用前端）
├── server.bat             # 仅启动后端（调试用）
├── webui.bat              # 仅启动 WebUI（调试用）
└── *.gguf                 # GGUF 模型文件（自动下载到项目根目录）
```

- **用户 → Open WebUI → llama.cpp**: Open WebUI 通过 `OPENAI_BASE_URL` 连接到 `http://127.0.0.1:11434/v1`（OpenAI 兼容 API）
- **CLI（备用）**: 直接调用 API，无中间层
- 关闭终端窗口即自动停止所有进程（llama-server 通过 `start /B` 在同一个控制台运行）

## Model Selection

模型配置统一在 `models.json` 中维护。新增模型只需在其中添加一项。

启动时通过 `start.bat` 或直接运行 `select_model.py` 选择模型。选择后 llama-server 直接加载对应的 GGUF 文件。

### Auto-Download

如果模型项包含 `url` 字段且 GGUF 文件不存在，选择时会自动提示下载：

```json
{
    "name": "qwen3-8b",
    "desc": "Qwen3-8B-Instruct (通用)",
    "gguf": "Qwen_Qwen3-8B-Q4_K_M.gguf",
    "url": "https://huggingface.co/bartowski/Qwen_Qwen3-8B-GGUF/resolve/main/Qwen_Qwen3-8B-Q4_K_M.gguf"
}
```

### MoE 模型

MoE 模型需要添加 `"moe": true`，启动时会自动设置 `--n-cpu-moe 32 --no-warmup` 参数。

## Key llama.cpp Flags

适合本项目的启动参数（设置于 `start.bat`）:

| 参数 | 作用 |
|------|------|
| `-ngl 24/99` | GPU 层数（24 适合 7-8B 模型 + 6GB 显存，99 适合 MoE 模型） |
| `--n-cpu-moe 35` | MoE 专家的前 35 层在 CPU 运行（适合 35B MoE 模型） |
| `-fa on` | Flash Attention（**必须开启**，节省长上下文内存） |
| `-ctk q8_0 -ctv q8_0` | KV Cache 8-bit 量化，减半内存占用 |
| `-c 16384` | 上下文长度 |
| `-np 1` | 单并发节省显存 |

## API

llama.cpp 提供了 OpenAI 兼容 API，直接可用。

#### `POST /v1/chat/completions`

标准 OpenAI Chat Completions 格式。

```json
{
  "model": "qwen3-8b",
  "messages": [{"role": "user", "content": "你好"}],
  "temperature": 0.9,
  "stream": false
}
```

#### `GET /v1/models`

模型列表。

```json
{
  "object": "list",
  "data": [{"id": "Qwen_Qwen3-8B-Q4_K_M.gguf", "object": "model"}]
}
```

#### 使用示例（OpenAI Python SDK）

```python
from openai import OpenAI

client = OpenAI(base_url="http://127.0.0.1:11434/v1", api_key="not-needed")
resp = client.chat.completions.create(
    model="Qwen_Qwen3-8B-Q4_K_M.gguf",
    messages=[{"role": "user", "content": "你好"}],
    stream=True,
)
for chunk in resp:
    print(chunk.choices[0].delta.content or "", end="")
```

## Quick Start

```bash
# 一键启动（选择模型 → 启动 llama-server → 启动 Open WebUI）
.\start.bat
```

首次启动 Open WebUI 时，在浏览器中注册一个管理员账号即可使用。Open WebUI 通过环境变量 `OPENAI_BASE_URL` 自动连接到本地的 llama.cpp。

关闭终端窗口即自动停止所有进程，无需手动清理。

## Bootstrap

`bootstrap.py` 在 `start.bat` / `server.bat` 启动时自动运行，负责下载 `llama-server.exe`。

工作流程：
1. 检测 CUDA 版本（通过 `nvidia-smi`）
2. 查询 GitHub API 获取最新 release tag
3. 下载对应平台的 zip（CUDA 11/12/13 或 CPU AVX2）
4. 解压到 `llama/` 目录
5. 如已存在则跳过（可用于版本升级时手动删除 exe 后重跑）

## Open WebUI 配置

Open WebUI 关键环境变量（设置于 `start.bat`）：

| 变量 | 值 | 说明 |
|------|-----|------|
| `OPENAI_API_BASE_URLS` | `http://127.0.0.1:11434/v1` | llama.cpp API 端点 |
| `OPENAI_API_KEYS` | `not-needed` | 占位符（llama.cpp 不校验 key） |
| `ENABLE_WEB_SEARCH` | `true` | 启用联网搜索 |
| `WEB_SEARCH_ENGINE` | `searxng` | 默认搜索引擎 |
| `HF_ENDPOINT` | `https://hf-mirror.com` | Hugging Face 国内镜像 |
| `SEARXNG_QUERY_URL` | `http://localhost:8889/search` | 本地 SearXNG 实例 |

如需在 Docker 中运行 Open WebUI：

```bash
docker run -d -p 3000:8080 \
  -e OPENAI_BASE_URL=http://host.docker.internal:11434/v1 \
  -e OPENAI_API_KEY=not-needed \
  -v open-webui:/app/backend/data \
  --name open-webui \
  ghcr.io/open-webui/open-webui:main
```

## Add a New Model

1. 在 `models.json` 中添加一项，包含 `name`、`desc`、`gguf`（文件名）
2. 可选：添加 `url` 字段（Hugging Face 直链）以启用自动下载
3. 可选：MoE 模型添加 `"moe": true`

## Notes

- 关闭终端窗口即可自动停止所有进程
- **Open WebUI** 是默认前端，启动后访问 `http://localhost:8080`
- **CLI（备用）**: 运行 `cli.bat` 使用终端交互
- **调试**: 如果 server 已在运行，可直接运行 `webui.bat` 单独启动 WebUI
- **升级 llama.cpp**: 修改 `bootstrap.py` 中的 `FALLBACK_TAG`，或直接删除 `llama/` 目录后重新运行（自动获取最新版）
