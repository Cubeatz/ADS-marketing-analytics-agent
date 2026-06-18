# 广告与归因平台支持说明

完整可选目录见 `config/ad-platforms.json`。首次配置第 1 题只展示已支持平台（A-I）。

## 已支持（可选）

| 字母 | 平台 | 类型 | MCP / 接入方式 |
|------|------|------|-----|
| A | Google Ads | 投放 | 官方 google-ads-mcp |
| B | Meta | 投放 | 官方 mcp.facebook.com/ads |
| C | Adjust | 归因/MMP | mcp-adjust（API Token） |
| D | AppsFlyer | 归因/MMP | 官方 mcp.appsflyer.com |
| E | LinkedIn Ads | 投放 | ads-mcp 自托管 |
| F | Microsoft Advertising | 投放 | mcp-bing-ads npm |
| G | Reddit Ads | 投放 | mcp-reddit-ads npm |
| H | TikTok Ads | 投放 | 官方 TikTok Ads MCP Server / Agentic Hub，需要官方 OAuth 或 MCP URL |
| I | Amazon Ads | 投放 | 官方 Amazon Ads MCP Server open beta，需要 Amazon Ads API 凭证和 MCP 端点 |

## 暂不支持（不会出现在第 1 题）

| 平台 | 原因 / 当前状态 |
|------|----------------|
| Snapchat Ads | 未找到 Snapchat 官方公开 MCP；目前主要是第三方报表/连接器。 |
| Pinterest Ads | Pinterest 官方资料主要是内部 MCP 生态/注册中心，没有公开 Pinterest Ads MCP 给普通广告账户配置。 |
| Apple Search Ads / Apple Ads | 未找到 Apple 官方公开 MCP；目前可见方案多为第三方实现。 |
| X（Twitter）Ads | 未找到 X 官方公开 Ads MCP；第三方项目较多，但不适合作为默认支持。 |
| Google DV360 | 未找到 Google 官方 DV360 专用 MCP；本项目先支持 Google Ads，不把 DV360 混入同一连接。 |
| Criteo | Criteo 有官方 MCP/agentic 方向，但公开资料显示仍偏 closed beta / 特定合作，不适合作为普通用户默认可选项。 |
| Taboola / Outbrain | 未找到官方公开 MCP；暂不纳入。 |

## 用户误选时

如果用户手动输入了第 1 题不存在的字母，直接提示“无效选项”，并要求重选 A-I。

## 分析过程中

如果用户要求查询未在 workspace 启用、或本表标记为暂不支持的平台，应明确告知当前无法分析，并引导从 `config/ad-platforms.json` 中选择支持项重新配置。

## 扩展支持

新增平台时，至少同步更新：

- `config/ad-platforms.json`
- `config/workspace.example.json`
- `config/accounts.example.json`
- `integrations/mcp-servers.core.json`
- `scripts/install.ps1` / `scripts/install.sh` 的平台到 MCP 名称映射
- `scripts/workspace_lib.py` 的默认平台列表
- `docs/AD-PLATFORMS.md` 的支持/暂不支持表
