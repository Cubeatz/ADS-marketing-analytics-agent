# IDE 集成模板

本目录包含各 AI 客户端的 MCP 配置模板。不要提交含真实密钥的配置。

## 使用

```powershell
# Windows：安装全部 IDE 配置
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide all

# 只装 Codex + Trae
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide codex,trae

# 中国大陆常用 IDE：生成可复制 JSON
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide trae
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide qoder
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide marscode
```

```bash
bash scripts/install.sh codex
bash scripts/install.sh antigravity
bash scripts/install.sh trae
```

## 核心 MCP 定义

核心定义见 `mcp-servers.core.json`。安装脚本会根据 `config/workspace.json` 中已启用的平台生成对应 IDE 的 MCP 配置。

## Trae / 通义灵码 / MarsCode

这些客户端通常通过 IDE 内的 MCP / 工具 / 服务配置页面添加服务。本项目不强行写入未知本地配置目录，而是生成可复制配置：

| 客户端 | 生成文件 | 安装命令 |
|--------|----------|----------|
| Trae / Trae CN | `integrations/trae/mcp.json` | `scripts/install.ps1 -Ide trae` |
| 通义灵码 / Qoder CN | `integrations/qoder-cn/mcp.json` | `scripts/install.ps1 -Ide qoder` 或 `-Ide lingma` |
| MarsCode | `integrations/marscode/mcp.json` | `scripts/install.ps1 -Ide marscode` |

打开对应 IDE 的 MCP / 工具 / 服务配置页面，手动粘贴 JSON 中的 `mcpServers`。

## 平台凭证

只配置首次问卷中选择的平台。

### Google Ads

仅选择 Google Ads 时需要：

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\你\.config\gcloud\application_default_credentials.json"
$env:GOOGLE_PROJECT_ID = "your-gcp-project"
$env:GOOGLE_ADS_DEVELOPER_TOKEN = "your-token"
```

### Adjust

仅选择 Adjust 时需要：

```powershell
$env:ADJUST_API_TOKEN = "your-adjust-token"
```

### TikTok Ads

仅选择 TikTok Ads 时需要使用 TikTok 官方 MCP / Agentic Hub 授权入口。若 IDE 需要 URL 方式配置：

```powershell
$env:TIKTOK_ADS_MCP_URL = "官方提供的 MCP URL"
```

### Amazon Ads

仅选择 Amazon Ads 时需要 Amazon Ads API 凭证和官方/伙伴/自托管 MCP 端点：

```powershell
$env:AMAZON_ADS_MCP_URL = "官方或伙伴提供的 MCP URL"
```

Meta / AppsFlyer 通常在 IDE 的 MCP OAuth 页面完成授权；LinkedIn / Microsoft / Reddit 按对应自托管 MCP 的说明准备 OAuth / Token。
