# 营销数据分析 Agent

这是给广告投放人员用的只读数据分析 Agent。你不需要懂命令行，也不需要安装数据库。你只要告诉 Agent 想看哪些平台、想要什么日报，Agent 会自动完成检查、配置、拉数、整理和投递。

当前可选平台：Google Ads、Meta Ads、Adjust、AppsFlyer、LinkedIn Ads、Microsoft Advertising、Reddit Ads、TikTok Ads、Amazon Ads。

- 只读分析：不会改广告账户、预算、素材或 campaign
- 无数据库：使用本地配置、临时数据目录和报告文件夹
- 自动交付：未配置飞书时自动生成本地 Word
- 多 IDE 支持：Cursor、Codex、Antigravity、Trae、通义灵码/Qoder、Claude、Windsurf、VS Code、Gemini CLI；MarsCode 可手动导入 MCP JSON

## 特色功能

| 功能 | 说明 |
|---|---|
| Agent 引导配置 | 用户只要说“帮我完成首次配置”，Agent 自动检查环境、问卷、生成配置和安装 MCP |
| 多平台只读拉数 | 支持广告投放平台和归因平台，默认不授予写权限 |
| OAuth 过期保护 | 定时日报前先检查授权；过期后自动尝试恢复 3 次，失败就生成空报告/失败报告并提醒用户 |
| 按天操作日志 | 每天写入 `logs/{date}/`，保留 30 天，超期自动清理 |
| temp 分层管理 | 原始数据、清洗数据、缓存、日志、导出文件分目录保存，不混放 |
| 本地 Word 报告 | 不配置飞书也能自动生成 DOCX |
| 飞书提醒 | 可推送日报，也可在授权失败时提醒重新授权 |
| 素材疲劳分析 | 根据 frequency、CTR 变化等指标识别疲劳素材 |
| 预算建议 | 根据预算利用率、CPA、展示损失等指标给出文字建议 |
| 归因差异对比 | 对比平台自报和 MMP 数据，解释归因窗口、时区、SKAN 等差异 |
| 多 IDE 支持 | Codex、Cursor、Trae、Qoder、Antigravity、Claude、Windsurf、VS Code、Gemini CLI 等 |

## 你只要这样说

| 你想做什么 | 对 Agent 说 |
|---|---|
| 第一次使用 | “帮我完成首次配置” |
| 不知道平台凭证从哪里拿 | “告诉我 Meta / Google / TikTok 的配置从哪里来” |
| 换一组广告平台 | “重新配置平台” |
| 配置当前 IDE 的 MCP | “帮我安装 MCP 到这个 IDE” |
| 生成日报 | “生成昨日营销日报” |
| 生成某几天日报 | “生成 2026-06-17 到 2026-06-19 的营销日报” |
| 设置每天自动日报 | “帮我配置每天早上 9 点自动生成日报” |

Agent 应该自动运行项目里的检查、问卷、安装、目录创建和报告脚本。除非系统权限不允许，否则不会让非技术用户自己复制命令。

## 第一次使用时会发生什么

你说“帮我完成首次配置”后，Agent 会自动：

1. 检查本机 Python、Node.js、pipx 等基础环境。
2. 用问卷确认你实际使用的平台、报告方式、数据目录、货币和飞书设置。
3. 根据已选平台生成 MCP 配置。
4. 告诉你每个平台还缺哪些 OAuth / API Token。
5. 创建 `temp/`、`reports/`、`output/documents/` 等目录。
6. 验证配置是否完整。

你只需要准备平台账户权限。各平台凭证从哪里拿、填到哪里，看这里：[各平台凭证配置指南](docs/PLATFORM-CREDENTIALS.md)。

## 先看哪里

| 你现在要做什么 | 直接看这里 |
|---|---|
| 各平台 token、账户 ID 从哪里来 | [各平台凭证配置指南](docs/PLATFORM-CREDENTIALS.md) |
| 支持哪些广告平台，哪些暂不支持 | [平台支持清单](docs/AD-PLATFORMS.md) |
| 自己的 IDE 怎么配 MCP | [IDE 支持矩阵](docs/IDE-MATRIX.md) |
| 部署到另一台电脑或远端机器 | [远端部署指南](docs/SETUP.md) |
| 每天自动跑日报 | [定时任务配置](docs/SCHEDULED-TASKS.md) |
| temp、reports 文件怎么放 | [临时数据目录规范](docs/TEMP-LAYOUT.md) |

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

## 支持的 IDE

| IDE | 说明 |
|-----|------|
| Codex | 自动生成项目级 `.codex/config.toml` |
| Antigravity | 自动生成 Antigravity MCP 配置，HTTP MCP 使用 `serverUrl` |
| Cursor | 自动生成 `.cursor/mcp.json`，并使用 `.cursor/rules/` |
| Trae / Trae CN | 生成可手动导入的 MCP JSON |
| 通义灵码 / Qoder CN | 生成可手动导入的 MCP JSON |
| Claude Desktop / Claude Code | 写入对应 MCP 配置 |
| Windsurf | 写入 Windsurf MCP 配置 |
| VS Code | 写入 `.vscode/mcp.json` |
| Gemini CLI | 写入 Gemini 配置 |
| MarsCode | 生成 `integrations/marscode/mcp.json`，有 MCP 入口时手动导入 |
| ChatGPT | 见 [ChatGPT MCP 说明](integrations/chatgpt.md) |

完整对照表见：[IDE 支持矩阵](docs/IDE-MATRIX.md)。

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

## 给技术人员

如果你需要手动排障，脚本在 `scripts/` 目录，MCP 模板在 `integrations/` 目录，示例配置在 `config/*.example.json`。普通广告投放用户不需要直接运行这些命令。
