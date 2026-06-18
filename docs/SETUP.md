# 远端部署指南（全 IDE）

面向 **非技术人员**。无需安装数据库，只需：Node.js、Python pipx、本项目文件夹、三个平台的 OAuth 授权。

## 第一步：首次配置（必做）

```powershell
powershell -ExecutionPolicy Bypass -File scripts\onboard.ps1
```

向导将询问：平台选择、账户 ID、报告时间、文件目录、飞书或本地 Word、其他偏好。  
详见 [ONBOARDING.md](ONBOARDING.md)

## 第二步：准备环境

### Windows

```powershell
# 1. 安装 Node.js（https://nodejs.org LTS）
node --version

# 2. 安装 Python 3.10+ 和 pipx
pip install pipx
pipx ensurepath

# 3. 克隆或复制本项目到远端电脑，例如：
# C:\Users\你的用户名\Projects\marketing-analytics-agent
```

### macOS

```bash
brew install node python pipx
pipx ensurepath
```

## 第二步：填写配置（无需数据库）

在项目根目录执行：

**Windows:**
```powershell
cd C:\path\to\marketing-analytics-agent
copy config\accounts.example.json config\accounts.json
copy config\thresholds.example.json config\thresholds.json
copy config\feishu.example.json config\feishu.json
notepad config\accounts.json
```

**macOS/Linux:**
```bash
cp config/accounts.example.json config/accounts.json
cp config/thresholds.example.json config/thresholds.json
cp config/feishu.example.json config/feishu.json
```

填写 `accounts.json` 里各 App 的 Google / Meta / AppsFlyer 账户 ID。

## 第三步：配置 Google Ads 凭证

```powershell
# 安装 Google Cloud CLI 后执行（一次性）
gcloud auth application-default login --scopes https://www.googleapis.com/auth/adwords,https://www.googleapis.com/auth/cloud-platform
```

记下输出的 credentials 文件路径，填入环境变量或安装脚本提示的位置。

还需在 [Google Ads API Center](https://ads.google.com/aw/apicenter) 申请 **Developer Token**。

## 第四步：安装 MCP 到你的 IDE

### 一键安装（推荐）

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide all
```

**macOS/Linux:**
```bash
bash scripts/install.sh all
```

支持的 `-Ide` 值：`cursor` | `codex` | `antigravity` | `claude` | `windsurf` | `vscode` | `gemini` | `all`

安装前设置环境变量（或在安装脚本交互中填写）：

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\你\.config\gcloud\application_default_credentials.json"
$env:GOOGLE_PROJECT_ID = "你的GCP项目ID"
$env:GOOGLE_ADS_DEVELOPER_TOKEN = "你的开发者令牌"
```

### 各 IDE 手动安装

详见 [IDE-MATRIX.md](IDE-MATRIX.md)。核心模板在 `integrations/` 目录。

#### Cursor
1. 复制 `integrations/cursor/mcp.json.template` → 项目 `.cursor/mcp.json`
2. 替换环境变量占位符
3. 重启 Cursor → MCP 面板完成 OAuth

#### Codex
1. 运行 `scripts/install.ps1 -Ide codex`
2. 或合并 `integrations/codex/config.toml.template` 到 `~/.codex/config.toml`
3. 项目根已有 `AGENTS.md`，Codex 会自动读取
4. 重启 Codex，运行 `/mcp` 检查连接

#### Antigravity
1. Agent 面板 → `...` → Manage MCP Servers → View raw config
2. 合并 `integrations/antigravity/mcp_config.json.template` 内容
3. **注意**：HTTP 服务用 `serverUrl`，不是 `url`
4. 重启 Antigravity，完成 Meta / AppsFlyer OAuth

#### Claude Desktop
1. 编辑 `%APPDATA%\Claude\claude_desktop_config.json`（Windows）
2. 合并 `integrations/claude-desktop/claude_desktop_config.json.template`
3. 重启 Claude Desktop

#### Windsurf
1. 编辑 `~/.codeium/windsurf/mcp_config.json`
2. 合并 `integrations/windsurf/mcp_config.json.template`

#### VS Code (Copilot MCP)
1. 复制 `integrations/vscode/mcp.json.template` → 项目 `.vscode/mcp.json`

#### Gemini CLI
1. 合并 `integrations/gemini-cli/settings.json.template` 到 `~/.gemini/settings.json`

#### ChatGPT
见 [integrations/chatgpt.md](../integrations/chatgpt.md)

## 第五步：验证连接

在任意已配置的 IDE 中说：

> 列出我可访问的 Google Ads 账户

> 查看 Meta 广告账户列表

> 查询 AppsFlyer 昨日安装数据

三个都能返回数据即配置成功。

## 飞书与 DOCX 投递

**未配置飞书时不会报错**，自动在指定目录生成 Word 文档。

编辑 `config/feishu.json`（从 `feishu.example.json` 复制）：

```json
{
  "enabled": false,
  "webhook_url": "",
  "docx_fallback": {
    "enabled": true,
    "custom_output_dir": "C:/Users/运营/Desktop/营销日报",
    "filename": "daily-report.docx"
  }
}
```

投递命令：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deliver-report.ps1
```

需安装 DOCX 依赖（一次性）：`pip install -r requirements.txt`

## 第六步：生成日报

对 Agent 说：

> 生成昨日营销日报

Agent 会自动运行投递脚本：

- 飞书已配置 → 推送飞书
- 未配置 → 生成 DOCX 到 `docx_fallback` 指定目录

手动投递：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deliver-report.ps1 -Date 2026-06-17
```

## 飞书机器人配置

1. 飞书群 → 设置 → 群机器人 → 添加自定义机器人
2. 复制 Webhook 地址到 `config/feishu.json` 的 `webhook_url`
3. 设置 `enabled: true`

## 常见问题

**Q: 必须装数据库吗？**  
A: 不需要。全部用 JSON 配置 + `reports/` 文件夹。

**Q: Codex 和 Cursor 能同时用吗？**  
A: 可以。共用项目文件夹，MCP 配置分别在各自用户目录。

**Q: Antigravity 连不上 Meta？**  
A: 确认用 `serverUrl` 字段；OAuth 选只读权限。

**Q: Google 报 developer token 仅测试账户？**  
A: 需在 API Center 申请 Explorer 或更高权限。

**Q: 没配飞书怎么办？**  
A: 不用配。在 `feishu.json` 里设 `docx_fallback.custom_output_dir` 为桌面等路径，报告会自动生成 Word 文件。
