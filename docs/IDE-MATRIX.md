# 各 IDE 支持矩阵

本项目是多平台只读营销数据分析 Agent，支持下列 AI 客户端。

| IDE / 客户端 | MCP 配置位置 | Agent 指令来源 | 安装方式 |
|-------------|-------------|---------------|---------|
| Cursor | 项目 `.cursor/mcp.json` | `.cursor/rules/*.mdc` | `scripts/install.ps1 -Ide cursor` |
| Codex CLI / IDE | `~/.codex/config.toml` 或项目 `.codex/config.toml` | 项目根 `AGENTS.md` | `scripts/install.ps1 -Ide codex` |
| Antigravity | `~/.gemini/antigravity/mcp_config.json` | 项目根 `AGENTS.md` | `scripts/install.ps1 -Ide antigravity` |
| Trae / Trae CN | IDE 内 MCP 设置页手动导入 JSON | 项目根 `AGENTS.md` | `scripts/install.ps1 -Ide trae` |
| 通义灵码 / Qoder CN | MCP 服务页手动添加 | 项目根 `AGENTS.md` | `scripts/install.ps1 -Ide qoder` 或 `-Ide lingma` |
| Claude Desktop | macOS `~/Library/Application Support/Claude/claude_desktop_config.json`；Windows `%APPDATA%\Claude\claude_desktop_config.json` | 对话引用 `AGENTS.md` | `scripts/install.ps1 -Ide claude-desktop` |
| Claude Code | `~/.claude/settings.json` | `AGENTS.md` 或 `CLAUDE.md` | `scripts/install.ps1 -Ide claude` |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` | `AGENTS.md` | `scripts/install.ps1 -Ide windsurf` |
| VS Code + Copilot | 项目 `.vscode/mcp.json` | `AGENTS.md` | `scripts/install.ps1 -Ide vscode` |
| Gemini CLI | `~/.gemini/settings.json` | `AGENTS.md` | `scripts/install.ps1 -Ide gemini` |
| MarsCode | 若当前版本提供 MCP/工具配置入口，则手动导入 JSON | `AGENTS.md` | `scripts/install.ps1 -Ide marscode` |
| ChatGPT | Settings / Connectors / 添加 MCP URL | 对话中说明只读分析 | 手动，见 `integrations/chatgpt.md` |

## HTTP MCP 字段

| IDE | 远程 MCP URL 字段 |
|-----|------------------|
| Cursor / Claude / Windsurf / VS Code / Trae / Qoder / MarsCode | `"url"` |
| Antigravity | `"serverUrl"` |
| Codex | TOML 中的 `url = "..."` |

## 平台 OAuth

只配置并验证首次问卷中选择的平台。

| 平台 | 连接方式 |
|------|----------|
| Google Ads | Google Cloud ADC + Developer Token |
| Meta Ads | Meta Business OAuth，只读权限 |
| Adjust | `ADJUST_API_TOKEN` |
| AppsFlyer | AppsFlyer MCP OAuth |
| LinkedIn / Microsoft / Reddit | 对应自托管 MCP 的 OAuth / Token |
| TikTok Ads | 官方 TikTok Ads MCP / Agentic Hub；必要时设置 `TIKTOK_ADS_MCP_URL` |
| Amazon Ads | 官方 Amazon Ads MCP Server open beta；必要时设置 `AMAZON_ADS_MCP_URL` |

## 推荐组合

| 场景 | 推荐 IDE |
|------|---------|
| 远端 Windows，想用 OpenAI 生成日报 | Codex |
| 已经在用 Cursor | Cursor |
| 中国大陆常用 AI IDE | Trae / Trae CN 或 通义灵码 / Qoder CN |
| 只用 Claude | Claude Desktop / Claude Code |
| 已有 VS Code 工作流 | VS Code + Copilot |

多个 IDE 可以共用同一个项目文件夹；MCP 配置安装到各自用户目录或项目配置中，项目内 `config/`、`temp/`、`reports/` 共用。

## 模板文件

```text
integrations/
├─ mcp-servers.core.json
├─ cursor/mcp.json.template
├─ codex/config.toml.template
├─ antigravity/mcp_config.json.template
├─ claude-desktop/claude_desktop_config.json.template
├─ claude-code/settings.json.template
├─ windsurf/mcp_config.json.template
├─ vscode/mcp.json.template
├─ gemini-cli/settings.json.template
├─ trae/mcp.json
├─ qoder-cn/mcp.json
├─ marscode/mcp.json
└─ chatgpt.md
```

Trae、Qoder/通义灵码、MarsCode 的本地配置路径在不同版本中可能不同，所以本项目只生成可复制 JSON，不强行写入未知目录。
