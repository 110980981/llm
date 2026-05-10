# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

本地部署 LLM（通过 llama.cpp），前端使用 Open WebUI。

## Architecture

```
llm/
├── frontend/
│   └── cli.py             # 交互式 CLI 客户端（备用）
├── llama/
│   └── llama-server.exe   # llama.cpp 服务器（带 CUDA 支持）
├── models.json            # 模型配置（唯一数据源）
├── select_model.py        # 模型选择交互脚本
├── start.bat              # 一键启动（唯一入口）
├── cli.bat                # 启动 CLI（备用前端）
├── server.bat             # 仅启动后端（调试用）
├── webui.bat              # 仅启动 WebUI（调试用）
└── *.gguf                 # GGUF 模型文件（项目根目录）
```

- **用户 → Open WebUI → llama.cpp**: Open WebUI 通过 `OPENAI_BASE_URL` 连接到 `http://127.0.0.1:11434/v1`（OpenAI 兼容 API）
- **CLI（备用）**: 直接调用 API，无中间层
- 关闭终端窗口即自动停止所有进程（llama-server 通过 `start /B` 在同一个控制台运行）

## Model Selection

模型配置统一在 `models.json` 中维护。新增模型只需在其中添加一项，确保 GGUF 文件在项目根目录。

启动时通过 `start.bat` 或直接运行 `select_model.py` 选择模型。选择后 llama-server 直接加载对应的 GGUF 文件。

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

## Open WebUI 配置

Open WebUI 关键环境变量（设置于 `start.bat`）：

| 变量 | 值 | 说明 |
|------|-----|------|
| `OPENAI_API_BASE_URLS` | `http://127.0.0.1:11434/v1` | llama.cpp API 端点 |
| `OPENAI_API_KEYS` | `not-needed` | 占位符（llama.cpp 不校验 key） |
| `ENABLE_WEB_SEARCH` | `true` | 启用联网搜索 |
| `WEB_SEARCH_ENGINE` | `brave` | 默认搜索引擎 |
| `HF_ENDPOINT` | `https://hf-mirror.com` | Hugging Face 国内镜像 |
| `SERPER_API_KEY` | `...` | Serper API key |
| `BRAVE_SEARCH_API_KEY` | `...` | Brave Search API key |
| `SEARXNG_QUERY_URL` | `https://searx.si/search` | SearXNG 实例地址 |

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

1. 下载 GGUF 文件放到项目根目录
2. 在 `models.json` 中添加一项，包含 `name`、`desc`、`gguf`（文件名）

## Notes

- 关闭终端窗口即可自动停止所有进程
- **Open WebUI** 是默认前端，启动后访问 `http://localhost:8080`
- **CLI（备用）**: 运行 `cli.bat` 使用终端交互
- **调试**: 如果 server 已在运行，可直接运行 `webui.bat` 单独启动 WebUI
- 目前使用 llama.cpp b9089（CUDA 13.1 版本），如需升级重新下载对应 release 替换 `llama/` 目录下的文件
