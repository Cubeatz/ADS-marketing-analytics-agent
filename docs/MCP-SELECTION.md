# MCP 选型说明

## 为什么不用 Markifact / Pipeboard

| 考量 | 第三方 SaaS MCP | 本方案 |
|------|----------------|--------|
| 费用 | 免费额度后收费 | 全免费 |
| 数据路径 | 经第三方服务器 | 官方 API 直连 |
| 凭证 | 存第三方 | Google 本地 ADC；Meta/AF 官方 OAuth |
| 写操作风险 | 有审批但仍经第三方 | 本 Agent 禁止写操作 |

## 三平台选型

### Google Ads — [googleads/google-ads-mcp](https://github.com/googleads/google-ads-mcp)

- **官方维护**，MIT 开源
- **天然只读**（当前版本仅 search / list / metadata）
- 本地 stdio，凭证走 Application Default Credentials
- 适合：花费、展示、点击、转化、GAQL 自定义报表

### Meta Ads — [Meta 官方 MCP](https://mcp.facebook.com/ads)

- Meta 2026 年发布的官方连接器
- HTTP OAuth，无需自建 Developer App
- OAuth 时选择**只读**权限即可
- Antigravity 注意用 `serverUrl` 字段

### AppsFlyer — [官方 Analytics MCP](https://mcp.appsflyer.com/auth/mcp)

- AppsFlyer 官方 Beta MCP
- 归因安装、渠道、SKAN、留存/LTV
- HTTP OAuth 或 Security Center Bearer Token
- 注意：与 `@appsflyer/sdk-mcp-server`（Android SDK 调试用）不同

## 为何不用三合一社区 MCP

如 Ryze、aidvertaiser 等虽然一个 Server 覆盖多平台，但通常：

- 远程托管（仍有中转）
- 或需自建多个 Developer App（对非技术人员门槛高）

本方案三个官方/半官方 MCP 组合，安全边界最清晰。

## Adjust 说明

若未来需要 Adjust 而非 AppsFlyer，可额外加 [bitscorp-mcp/mcp-adjust](https://github.com/bitscorp-mcp/mcp-adjust)（本地 stdio + API Key），与现有三 MCP 并列，无需改架构。
