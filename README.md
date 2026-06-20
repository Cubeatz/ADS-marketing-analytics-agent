# 营销数据分析 Agent

面向非技术广告投放人员的只读数据分析 Agent。它不会改广告账户，只帮助你拉取所选平台的数据、整理日报，并输出本地 Word 或飞书消息。

当前可选平台：Google Ads、Meta Ads、Adjust、AppsFlyer、LinkedIn Ads、Microsoft Advertising、Reddit Ads、TikTok Ads、Amazon Ads。

- 无数据库：使用 JSON 配置、`temp/` 临时数据和 `reports/` 报告文件夹
- 只读分析：默认不授权写入广告账户
- 日报交付：未配置飞书时自动生成 DOCX
- 多 IDE 支持：Cursor、Codex、Antigravity、Trae、通义灵码/Qoder、Claude、Windsurf、VS Code、Gemini CLI；MarsCode 生成手动 MCP JSON

## 先看哪里

| 你现在要做什么 | 直接看这里 |
|---|---|
| 第一次使用，想一步步装好 | [首次使用](#首次使用) |
| 不知道各平台 token、账户 ID 从哪来 | [各平台凭证配置指南](docs/PLATFORM-CREDENTIALS.md) |
| 想知道支持哪些广告平台，哪些暂不支持 | [平台支持清单](docs/AD-PLATFORMS.md) |
| 想知道自己的 IDE 怎么配 MCP | [IDE 支持矩阵](docs/IDE-MATRIX.md) |
| 想部署到另一台电脑或远端机器 | [远端部署指南](docs/SETUP.md) |
| 想配置每天自动跑日报 | [定时任务配置](docs/SCHEDULED-TASKS.md) |
| 想了解 temp、reports 文件怎么放 | [临时数据目录规范](docs/TEMP-LAYOUT.md) |

## 首次使用

首次使用请运行一键启动，它会依次完成环境检查、问卷配置和 MCP 安装：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\start.ps1
```

如果你只想跑问卷：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\onboard.ps1
```

问卷第 1 题只选择你实际投放或归因使用的平台。后续只需要配置已选平台的 OAuth / API Token，不需要为了示例去设置 Google 环境变量。

也可以在对话里一次性回复，例如：

```text
1AB 2A 3A 7A 8A 9A
```

表示：选择 Google + Meta、一次性使用、本地 Word、桌面目录、USD、不使用飞书。每题 A 是推荐默认，Z/跳过等同于 A。

## 快速开始

```powershell
# 1. 运行首次配置，选择实际需要的平台
powershell -ExecutionPolicy Bypass -File scripts\start.ps1

# 2. 按已选平台补全 OAuth / API Token
#    具体从哪里拿、填到哪里：docs/PLATFORM-CREDENTIALS.md
#    只有选择 Google Ads 时，才需要 Google Ads 环境变量。

# 3. 安装到你实际使用的 IDE
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide codex
# 也可使用 -Ide cursor / trae / qoder / antigravity / all

# 4. 重启 IDE，完成所选平台的 OAuth / API Token 配置
# 5. 对 Agent 说：生成昨日营销日报
```

macOS/Linux：

```bash
bash scripts/install.sh codex
```

平台凭证说明请直接看：[各平台配置从哪里来](docs/PLATFORM-CREDENTIALS.md)。

## 支持的 IDE

| IDE | 安装命令 | 说明 |
|-----|---------|------|
| Codex | `install.ps1 -Ide codex` | 使用项目级 `.codex/config.toml` |
| Antigravity | `install.ps1 -Ide antigravity` | HTTP MCP 使用 `serverUrl` |
| Cursor | `install.ps1 -Ide cursor` | 使用 `.cursor/mcp.json` 和 `.cursor/rules/` |
| Trae / Trae CN | `install.ps1 -Ide trae` | 生成可手动导入的 MCP JSON |
| 通义灵码 / Qoder CN | `install.ps1 -Ide qoder` 或 `-Ide lingma` | 生成可手动导入的 MCP JSON |
| Claude Desktop | `install.ps1 -Ide claude-desktop` | 写入 Claude Desktop 配置 |
| Claude Code | `install.ps1 -Ide claude` | 写入 Claude Code 配置 |
| Windsurf | `install.ps1 -Ide windsurf` | 写入 Windsurf 配置 |
| VS Code | `install.ps1 -Ide vscode` | 写入 `.vscode/mcp.json` |
| Gemini CLI | `install.ps1 -Ide gemini` | 写入 Gemini 配置 |
| MarsCode | `install.ps1 -Ide marscode` | 生成 `integrations/marscode/mcp.json`，有 MCP 入口时手动导入 |
| ChatGPT | 手动 | 见 [ChatGPT MCP 说明](integrations/chatgpt.md) |

完整对照表见：[IDE 支持矩阵](docs/IDE-MATRIX.md)。

## 支持的平台

| 平台 | 配置说明 |
|---|---|
| Google Ads | [Google Ads 凭证配置](docs/PLATFORM-CREDENTIALS.md#google-ads) |
| Meta Ads | [Meta Ads 凭证配置](docs/PLATFORM-CREDENTIALS.md#meta-ads) |
| Adjust | [Adjust 凭证配置](docs/PLATFORM-CREDENTIALS.md#adjust) |
| AppsFlyer | [AppsFlyer 凭证配置](docs/PLATFORM-CREDENTIALS.md#appsflyer) |
| LinkedIn Ads | [LinkedIn Ads 凭证配置](docs/PLATFORM-CREDENTIALS.md#linkedin-ads) |
| Microsoft Advertising | [Microsoft Advertising 凭证配置](docs/PLATFORM-CREDENTIALS.md#microsoft-advertising) |
| Reddit Ads | [Reddit Ads 凭证配置](docs/PLATFORM-CREDENTIALS.md#reddit-ads) |
| TikTok Ads | [TikTok Ads 凭证配置](docs/PLATFORM-CREDENTIALS.md#tiktok-ads) |
| Amazon Ads | [Amazon Ads 凭证配置](docs/PLATFORM-CREDENTIALS.md#amazon-ads) |

暂不支持的平台和原因见：[平台支持清单](docs/AD-PLATFORMS.md)。

## 目录结构

```text
marketing-analytics-agent/
├─ AGENTS.md
├─ config/
│  ├─ workspace.example.json
│  └─ accounts.example.json
├─ temp/
│  ├─ raw/{date}/{platform}/{category}/
│  ├─ processed/
│  ├─ cache/
│  ├─ logs/
│  └─ exports/
├─ output/documents/
├─ reports/
├─ docs/
├─ scripts/
├─ integrations/
└─ .cursor/rules/
```

## 文档

| 文档 | 内容 |
|------|------|
| [各平台凭证配置指南](docs/PLATFORM-CREDENTIALS.md) | 各平台凭证从哪里来、填到哪里、怎么验证 |
| [平台支持清单](docs/AD-PLATFORMS.md) | 平台支持清单和暂不支持原因 |
| [远端部署指南](docs/SETUP.md) | 远端部署和平台凭证配置 |
| [首次问卷说明](docs/ONBOARDING.md) | 首次问卷每一题怎么选 |
| [IDE 支持矩阵](docs/IDE-MATRIX.md) | 各 IDE 配置差异 |
| [定时任务配置](docs/SCHEDULED-TASKS.md) | 每天自动生成日报 |
| [临时数据目录规范](docs/TEMP-LAYOUT.md) | temp 分层目录规范 |
| [GitHub 使用说明](docs/GITHUB.md) | 推送到 GitHub / 克隆 |
| [架构与数据流](docs/ARCHITECTURE.md) | 项目架构与数据流 |
| [MCP 选型理由](docs/MCP-SELECTION.md) | MCP 选择依据 |

## 常用指令

- “生成昨日营销日报”
- “分析 Meta 素材疲劳”
- “对比投放平台自报数据和归因平台差异”
- “哪些 campaign 预算利用率超过 90%？”
