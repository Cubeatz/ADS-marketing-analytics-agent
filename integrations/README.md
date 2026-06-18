# IDE 集成模板

本目录包含各 AI 客户端的 MCP 配置模板。不要直接提交含真实密钥的配置。

## 使用

```powershell
# Windows — 安装全部 IDE 配置
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide all

# 只装 Codex + Antigravity
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide codex,antigravity
```

```bash
# macOS/Linux
bash scripts/install.sh codex
bash scripts/install.sh antigravity
```

## 核心 MCP 定义

见 [mcp-servers.core.json](./mcp-servers.core.json)。

## Antigravity 特别注意

HTTP MCP 必须使用 **`serverUrl`** 字段，不能用 `url`。

## 环境变量

安装前设置（Windows PowerShell）：

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\你\.config\gcloud\application_default_credentials.json"
$env:GOOGLE_PROJECT_ID = "your-gcp-project"
$env:GOOGLE_ADS_DEVELOPER_TOKEN = "your-token"
```
