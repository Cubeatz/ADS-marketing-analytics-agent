# 远端部署指南（全 IDE）

这份指南面向非技术广告投放人员。你不需要安装数据库，只需要这个项目文件夹，以及首次配置中已选择平台所需的 OAuth / API Token。

## 第一步：首次配置

```powershell
powershell -ExecutionPolicy Bypass -File scripts\onboard.ps1
```

向导会询问：平台选择、账户 ID、报告时间、文件目录、飞书或本地 Word、其他偏好。详见 `docs/ONBOARDING.md`。

## 第二步：准备基础环境

Windows：

```powershell
node --version
python --version
pip install pipx
pipx ensurepath
```

macOS：

```bash
brew install node python pipx
pipx ensurepath
```

## 第三步：按已选平台准备凭证

只配置你在首次问卷第 1 题选择的平台；未选择的平台可以跳过。

### Google Ads（仅选择 Google Ads 时）

安装 Google Cloud CLI 后执行一次：

```powershell
gcloud auth application-default login --scopes https://www.googleapis.com/auth/adwords,https://www.googleapis.com/auth/cloud-platform
```

还需要在 Google Ads API Center 申请 Developer Token。安装前设置：

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\你\.config\gcloud\application_default_credentials.json"
$env:GOOGLE_PROJECT_ID = "你的GCP项目ID"
$env:GOOGLE_ADS_DEVELOPER_TOKEN = "你的开发者令牌"
```

### Meta Ads（仅选择 Meta 时）

在对应 IDE 的 MCP/OAuth 页面连接：

```text
https://mcp.facebook.com/ads
```

授权时选择只读权限。

### Adjust（仅选择 Adjust 时）

```powershell
$env:ADJUST_API_TOKEN = "你的 Adjust API Token"
```

### AppsFlyer（仅选择 AppsFlyer 时）

在对应 IDE 的 MCP/OAuth 页面连接：

```text
https://mcp.appsflyer.com/auth/mcp
```

### LinkedIn / Microsoft Advertising / Reddit（仅选择对应平台时）

这些平台使用自托管 npm MCP。请先确认 Node.js 可用，并按平台 API 要求准备 OAuth / Token。

### TikTok Ads（仅选择 TikTok Ads 时）

使用 TikTok 官方 TikTok Ads MCP Server / Agentic Hub 授权入口。若你的 IDE 需要 URL 方式配置：

```powershell
$env:TIKTOK_ADS_MCP_URL = "官方提供的 MCP URL"
```

### Amazon Ads（仅选择 Amazon Ads 时）

Amazon Ads MCP Server 已进入官方 open beta。使用前需要 Amazon Ads API 凭证，以及官方、伙伴或自托管 MCP 端点：

```powershell
$env:AMAZON_ADS_MCP_URL = "官方或伙伴提供的 MCP URL"
```

## 第四步：安装 MCP 到你的 IDE

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide all
```

macOS/Linux：

```bash
bash scripts/install.sh all
```

支持的 `-Ide` 值：

```text
cursor | codex | antigravity | trae | qoder | lingma | marscode | claude | claude-desktop | windsurf | vscode | gemini | all
```

安装脚本会根据 `config/workspace.json` 只生成已选平台的 MCP 配置。

## 第五步：验证连接

在已配置的 IDE 中说：

```text
列出我已连接的平台账户
```

也可以只测试你实际选择的平台，例如：

```text
查看 Meta 广告账户列表
查询 AppsFlyer 昨日安装数据
查询 Adjust 昨日归因数据
```

未选择的平台不需要测试。

## 第六步：生成日报

对 Agent 说：

```text
生成昨日营销日报
```

手动投递：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deliver-report.ps1 -Date 2026-06-17
```

未配置飞书时，会自动在指定目录生成 Word 文档。

## 常见问题

**必须装数据库吗？**
不需要。全部使用 JSON 配置、`temp/` 临时数据和 `reports/` 报告文件夹。

**为什么 README 里提到 Google，但我没投 Google？**
Google 只是一个可选平台。只有你在第 1 题选择 Google Ads 时，才需要配置 Google 相关环境变量。

**暂不支持的平台怎么办？**
见 `docs/AD-PLATFORMS.md` 的“暂不支持”表。那里会说明是没有官方公开 MCP、只有第三方方案，还是处于封闭测试。

**没配飞书怎么办？**
不用配置。系统会自动生成本地 DOCX。
