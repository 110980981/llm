# LLM Local

本地部署 LLM，使用 [llama.cpp](https://github.com/ggml-org/llama.cpp) 后端 + [Open WebUI](https://github.com/open-webui/open-webui) 前端。

## 快速开始

```bash
.\start.bat
```

选择模型 → 自动启动 llama-server → 打开 Open WebUI → 注册账号即可使用。

关闭终端窗口即自动停止所有进程。

## 架构

```
llm/
├── start.bat        # 一键启动（唯一入口）
├── server.bat       # 仅启动 llama-server（调试用）
├── webui.bat        # 仅启动 Open WebUI（调试用）
├── cli.bat          # 启动 CLI 终端交互（备用）
├── select_model.py  # 模型选择脚本
├── models.json      # 模型配置
├── frontend/
│   └── cli.py       # CLI 客户端（备用）
└── llama/
    └── llama-server.exe  # llama.cpp 服务器（CUDA）
```

## 配置

| 变量 | 说明 |
|------|------|
| `OPENAI_API_BASE_URLS` | llama.cpp API 端点 |
| `ENABLE_WEB_SEARCH` | 联网搜索 |
| `WEB_SEARCH_ENGINE` | 搜索引擎 |
| `HF_ENDPOINT` | Hugging Face 镜像 |

详细配置见 `start.bat` 和 `CLAUDE.md`。

## 添加模型

1. 下载 GGUF 文件放到项目根目录
2. 在 `models.json` 中添加一项

## 依赖

- Python 3.11+
- llama.cpp b9089（CUDA 13.1）
- Open WebUI（首次启动自动安装）
