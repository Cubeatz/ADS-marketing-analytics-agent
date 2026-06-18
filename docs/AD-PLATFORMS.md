# 广告与归因平台支持说明

完整目录见 `config/ad-platforms.json`。问卷第 1 题**仅展示已支持平台（A–G）**。

## 已支持（✓）

| 字母 | 平台 | 类型 | MCP |
|------|------|------|-----|
| A | Google Ads | 投放 | 官方 google-ads-mcp |
| B | Meta | 投放 | 官方 mcp.facebook.com/ads |
| C | Adjust | 归因/MMP | mcp-adjust（API Token） |
| D | AppsFlyer | 归因/MMP | 官方 mcp.appsflyer.com |
| E | LinkedIn Ads | 投放 | ads-mcp 自托管 |
| F | Microsoft Advertising | 投放 | mcp-bing-ads npm |
| G | Reddit Ads | 投放 | mcp-reddit-ads npm |

## 暂不支持（✗）— 不在第 1 题选项中

| 字母 | 平台 |
|------|------|
| H | TikTok Ads |
| I | Snapchat Ads |
| J | Pinterest Ads |
| K | Amazon Ads |
| L | Apple Search Ads |
| M | X（Twitter）Ads |
| N | Google DV360 |
| O | Criteo |
| P | Taboola / Outbrain |

## 用户误选时

若用户手动输入了第 1 题不存在的字母（例如 H），直接提示「无效选项」并要求重选 A–G。

## 分析过程中

若用户要求查询**未在 workspace 启用**或**目录中标记为不支持**的平台，应明确告知不可分析，并引导从 `config/ad-platforms.json` 中选支持项重新配置。

## 扩展支持

新增平台时：编辑 `ad-platforms.json`（`supported: true`）、`workspace.example.json`、`integrations/mcp-servers.core.json` 与 temp 分类。
