# 营销数据分析 Agent

面向 **非技术人员** 的只读数据分析 Agent，覆盖 **Google Ads、Meta Ads、Adjust、AppsFlyer、LinkedIn Ads、Microsoft Advertising、Reddit Ads**。

- **无数据库** — JSON 配置 + `reports/` 文件夹
- **只读分析** — 不改广告账户
- **飞书日报** — Webhook 推送；未配置时自动生成 **DOCX**
- **全 IDE 支持** — Cursor、Codex、Antigravity、Claude、Windsurf、VS Code、Gemini CLI

## 首次使用（必做）

**未完成配置前 Agent 不会开始分析。**

一键启动（推荐，自动完成：环境检查 → 问卷 → MCP 安装）：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\start.ps1
```

首次会先检查本机是否已安装 **Python 3.10+**（齐全则不提示）；缺 Python 时会给出安装说明。

也可在对话中一次性回复，例如：

**`1AB 2A 3A 7A 8A 9A`**

（每题 **A = 推荐默认**；Z / 跳过 = 等同选 A。表示：Google+Meta、一次性、本地 Word、桌面目录、USD、不用飞书；一次性模式会继续询问单天/多天，默认近 3 天。）

或仅运行问卷：`powershell -File scripts\onboard.ps1`

## 快速开始（配置完成后）

```powershell
# 1. 复制项目到远端电脑
# 2. 设置 Google 环境变量（见 docs/SETUP.md）
# 3. 一键安装（按实际使用的 IDE 选择）
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide codex
# 或 -Ide antigravity / cursor / all

# 4. 填写 config\accounts.json
# 5. 重启 IDE，完成所选平台 OAuth / API Token 配置
# 6. 对话：「生成昨日营销日报」
```

macOS/Linux：`bash scripts/install.sh codex`

## 支持的 IDE

| IDE | 安装命令 | Agent 指令 |
|-----|---------|-----------|
| **Codex** | `install.ps1 -Ide codex` | `AGENTS.md` |
| **Antigravity** | `install.ps1 -Ide antigravity` | `AGENTS.md` |
| **Cursor** | `install.ps1 -Ide cursor` | `.cursor/rules/` |
| Claude Desktop | `install.ps1 -Ide claude-desktop` | 对话引用 `AGENTS.md` |
| Claude Code | `install.ps1 -Ide claude` | `CLAUDE.md` |
| Windsurf | `install.ps1 -Ide windsurf` | `AGENTS.md` |
| VS Code | `install.ps1 -Ide vscode` | `AGENTS.md` |
| Gemini CLI | `install.ps1 -Ide gemini` | `AGENTS.md` |
| ChatGPT | 手动 | [integrations/chatgpt.md](integrations/chatgpt.md) |

完整对照表：[docs/IDE-MATRIX.md](docs/IDE-MATRIX.md)

## 项目结构

```
marketing-analytics-agent/
├── AGENTS.md
├── config/
│   ├── workspace.example.json   # 总配置模板
│   └── accounts.example.json
├── temp/                        # 分层临时数据（见 TEMP-LAYOUT.md）
│   ├── raw/{date}/{platform}/{category}/
│   ├── processed/
│   ├── cache/
│   ├── logs/
│   └── exports/
├── output/documents/            # 本地 Word 报告
├── reports/                     # Markdown 日报
├── docs/ONBOARDING.md           # 8 步引导（Agent 必读）
├── scripts/
│   ├── start.ps1 / .sh          # 一键首次启动（推荐）
│   ├── onboard.ps1 / .sh        # 仅问卷向导
│   ├── install.ps1 / .sh
│   ├── deliver-report.*
│   └── export-report-docx.py
├── integrations/                # 各 IDE 的 MCP 模板
└── .cursor/rules/
```

## 文档

| 文档 | 内容 |
|------|------|
| [TEMP-LAYOUT.md](docs/TEMP-LAYOUT.md) | **temp 分层目录规范** |
| [AD-PLATFORMS.md](docs/AD-PLATFORMS.md) | **平台支持清单（✓/✗）** |
| [ONBOARDING.md](docs/ONBOARDING.md) | 首次使用引导 |
| [SETUP.md](docs/SETUP.md) | 远端部署全流程 |
| [GITHUB.md](docs/GITHUB.md) | **推送到 GitHub / 克隆** |
| [IDE-MATRIX.md](docs/IDE-MATRIX.md) | 各 IDE 配置差异 |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | 架构与数据流 |
| [MCP-SELECTION.md](docs/MCP-SELECTION.md) | MCP 选型理由 |

## 典型指令

- 「生成今日营销日报并推送到飞书」
- 「分析 Meta 素材疲劳」
- 「对比 Google 自报安装和 AppsFlyer 差异」
- 「哪些 campaign 预算利用率超过 90%？」
