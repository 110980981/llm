# LLM Local

本地部署 LLM，使用 [llama.cpp](https://github.com/ggml-org/llama.cpp) 后端 + [Open WebUI](https://github.com/open-webui/open-webui) 前端。

## 快速开始

```bash
.\start.bat
```

首次启动时自动：
1. 下载 **llama.cpp**（自动检测 CUDA / CPU）
2. 选择模型后自动下载 GGUF 文件（需配置下载链接）
3. 启动 Open WebUI → 注册账号即可使用

关闭终端窗口即自动停止所有进程。

## 架构

```
llm/
├── start.bat        # 一键启动（唯一入口）
├── bootstrap.py     # 自动下载 llama.cpp（CUDA 检测）
├── select_model.py  # 模型选择 + 自动下载
├── models.json      # 模型配置（含下载链接）
├── server.bat       # 仅启动 llama-server（调试用）
├── webui.bat        # 仅启动 Open WebUI（调试用）
├── cli.bat          # 启动 CLI 终端交互（备用）
├── frontend/
│   └── cli.py       # CLI 客户端（备用）
├── llama/           # bootstrap 自动生成
│   └── llama-server.exe
└── *.gguf           # 模型文件（自动下载到项目根目录）
```

## 配置模型下载

`models.json` 中每个模型支持 `url` 字段，配置后 `select_model.py` 会自动下载：

```json
{
    "4": {
        "name": "qwen3-8b",
        "desc": "Qwen3-8B-Instruct (通用)",
        "gguf": "Qwen_Qwen3-8B-Q4_K_M.gguf",
        "url": "https://huggingface.co/bartowski/Qwen_Qwen3-8B-GGUF/resolve/main/Qwen_Qwen3-8B-Q4_K_M.gguf"
    }
}
```

## 添加模型

1. 在 `models.json` 中添加一项，包含 `name`、`desc`、`gguf`（文件名）
2. 可选：添加 `url` 字段以启用自动下载
3. 可选：MoE 模型添加 `"moe": true`

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `OPENAI_API_BASE_URLS` | llama.cpp API 端点 | `http://127.0.0.1:11434/v1` |
| `ENABLE_WEB_SEARCH` | 联网搜索 | `true` |
| `WEB_SEARCH_ENGINE` | 搜索引擎 | `brave` |
| `HF_ENDPOINT` | Hugging Face 镜像 | `https://hf-mirror.com` |
| `SERPER_API_KEY` | Serper API key | — |
| `BRAVE_SEARCH_API_KEY` | Brave Search API key | — |

## 依赖

- Python 3.11+
- llama.cpp（自动下载，支持 CUDA 11/12/13 及 CPU 回退）
- Open WebUI（`pip install open-webui`，首次启动自动安装）
