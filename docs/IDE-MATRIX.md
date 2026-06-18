# 各 IDE 支持矩阵

本项目为 **Google Ads + Meta Ads + AppsFlyer** 只读分析 Agent，支持以下 AI 客户端。

| IDE / 客户端 | MCP 配置位置 | Agent 指令来源 | 安装方式 |
|-------------|-------------|---------------|---------|
| **Cursor** | 项目 `.cursor/mcp.json` 或 `~/.cursor/mcp.json` | `.cursor/rules/*.mdc` + `.cursor/skills/` | `scripts/install.ps1 -Ide cursor` |
| **Codex CLI / IDE** | `~/.codex/config.toml` 或项目 `.codex/config.toml` | 项目根 `AGENTS.md` | `scripts/install.ps1 -Ide codex` |
| **Antigravity** | `~/.gemini/antigravity/mcp_config.json` | 项目根 `AGENTS.md` | `scripts/install.ps1 -Ide antigravity` |
| **Claude Desktop** | `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) 或 `%APPDATA%\Claude\claude_desktop_config.json` (Win) | 粘贴 `AGENTS.md` 摘要或 @ 引用项目 | 手动，见 SETUP.md |
| **Claude Code** | `~/.claude/settings.json` → `mcpServers` | `AGENTS.md` 或 `CLAUDE.md` | `scripts/install.ps1 -Ide claude` |
| **Windsurf** | `~/.codeium/windsurf/mcp_config.json` | `AGENTS.md` | `scripts/install.ps1 -Ide windsurf` |
| **VS Code + Copilot** | 项目 `.vscode/mcp.json` 或用户 settings | `AGENTS.md` | `scripts/install.ps1 -Ide vscode` |
| **Gemini CLI** | `~/.gemini/settings.json` | `AGENTS.md` | `scripts/install.ps1 -Ide gemini` |
| **ChatGPT** | 设置 → Connectors → 添加 MCP URL | 无自动规则，对话时说明只读分析 | 手动，见 `integrations/chatgpt.md` |

## 关键差异

### HTTP MCP 字段名

| IDE | 远程 MCP URL 字段 |
|-----|------------------|
| Cursor / Claude / Windsurf / VS Code | `"url"` |
| **Antigravity** | `"serverUrl"`（不是 `url`） |
| Codex | `url = "..."` in TOML |

### 配置文件格式

| IDE | 格式 |
|-----|------|
| Cursor, Claude, Windsurf, Antigravity, VS Code | JSON |
| Codex | TOML |

### OAuth 流程

三个 MCP 均需浏览器 OAuth（首次连接）：

1. **google-ads** — Google Cloud ADC（`gcloud auth application-default login`）
2. **meta-ads** — Meta Business OAuth，选 **只读** 权限
3. **appsflyer** — AppsFlyer 账户 OAuth

## 推荐组合（非技术人员）

| 场景 | 推荐 IDE |
|------|---------|
| 远端 Windows，OpenAI 生态 | **Codex** |
| Google 生态 / 免费 IDE | **Antigravity** |
| 已有 Cursor 订阅 | **Cursor** |
| 只用 Claude | **Claude Desktop** |

三种 IDE 可共用同一项目文件夹；MCP 配置安装到各自用户目录，**项目内 config/ 和 reports/ 共享**。

## 模板文件位置

```
integrations/
├── mcp-servers.core.json      # 核心定义
├── cursor/mcp.json.template
├── codex/config.toml.template
├── antigravity/mcp_config.json.template
├── claude-desktop/claude_desktop_config.json.template
├── claude-code/settings.json.template
├── windsurf/mcp_config.json.template
├── vscode/mcp.json.template
├── gemini-cli/settings.json.template
└── chatgpt.md
```
