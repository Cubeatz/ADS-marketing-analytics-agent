# IDE 集成模板

本目录包含各 AI 客户端的 MCP 配置模板和生成结果。普通广告投放用户不需要直接编辑这些文件；Agent 会根据首次配置结果自动生成。

## Agent 使用方式

当用户说“帮我安装 MCP 到某个 IDE”时，Agent 应该：

1. 读取 `config/workspace.json`，确认已启用平台。
2. 读取 `integrations/mcp-servers.core.json`。
3. 调用项目安装脚本生成目标 IDE 的 MCP 配置。
4. 检查生成文件是否包含已选平台。
5. 对需要用户 OAuth 的平台，引导用户在 IDE 里完成授权。

不要让非技术用户自己复制安装命令。

## 核心 MCP 定义

核心定义见：[mcp-servers.core.json](mcp-servers.core.json)。

安装脚本会根据 `config/workspace.json` 中已启用的平台生成对应 IDE 的 MCP 配置。如果首次配置尚未完成，则生成全量模板，方便后续选择。

## Trae / 通义灵码 / MarsCode

这些客户端的本地配置路径在不同版本中可能不同。本项目不强行写入未知目录，而是生成可复制配置：

| 客户端 | 生成文件 |
|--------|----------|
| Trae / Trae CN | `integrations/trae/mcp.json` |
| 通义灵码 / Qoder CN | `integrations/qoder-cn/mcp.json` |
| MarsCode | `integrations/marscode/mcp.json` |

Agent 应告诉用户打开对应 IDE 的 MCP / 工具 / 服务配置页面，并导入 JSON 中的 `mcpServers`。

## 平台凭证

只配置首次问卷中选择的平台。各平台凭证来源见：[各平台凭证配置指南](../docs/PLATFORM-CREDENTIALS.md)。

常见情况：

- Meta / AppsFlyer 通常在 IDE 的 MCP OAuth 页面完成授权。
- Google Ads 需要 Google Cloud ADC、Developer Token 和 Customer ID。
- Adjust 需要 `ADJUST_API_TOKEN`。
- TikTok Ads 如需 URL 配置，使用 `TIKTOK_ADS_MCP_URL`。
- Amazon Ads 如需 URL 配置，使用 `AMAZON_ADS_MCP_URL`。

不要把真实 token、secret、webhook 提交到 GitHub。
