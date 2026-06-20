# 各平台凭证配置指南

这份文档告诉你：每个平台需要什么信息、从哪里拿、交给 Agent 后会写到哪里。

先记住三条：

- 只配置首次问卷第 1 题选择的平台。
- 不要把 token、secret、webhook 提交到 GitHub。
- 能选权限时优先选择只读权限；本项目只做分析，不改广告账户。

## 速查表

| 平台 | 需要准备 | 从哪里来 | Agent 会写到哪里 |
|------|----------|----------|------------------|
| Google Ads | Customer ID、Developer Token、Google Cloud 凭证 | Google Ads 后台、Google Ads API Center、Google Cloud | `config/accounts.json` 和本地环境变量 |
| Meta Ads | Ad Account ID、OAuth 授权 | Meta Ads Manager、IDE 的 MCP OAuth 页面 | `config/accounts.json` 和 IDE OAuth |
| Adjust | App 名称、API Token | Adjust Dashboard | `config/accounts.json` 和 `ADJUST_API_TOKEN` |
| AppsFlyer | App ID、OAuth 授权 | AppsFlyer 控制台、AppsFlyer MCP 授权页 | `config/accounts.json` 和 IDE OAuth |
| LinkedIn Ads | Ad Account ID、OAuth 权限 | LinkedIn Campaign Manager / Marketing API | `config/accounts.json` 和对应 MCP OAuth |
| Microsoft Advertising | Account ID、Developer Token、OAuth | Microsoft Advertising 后台 / Developer Portal | `config/accounts.json` 和对应 MCP OAuth |
| Reddit Ads | Account ID、OAuth | Reddit Ads Manager / Reddit Ads API | `config/accounts.json` 和对应 MCP OAuth |
| TikTok Ads | Advertiser ID、官方 MCP/OAuth 入口 | TikTok for Business / API for Business | `config/accounts.json` 和 `TIKTOK_ADS_MCP_URL`（如需） |
| Amazon Ads | Profile ID、Ads API 凭证、MCP 端点 | Amazon Ads API / Advanced Tools Center | `config/accounts.json` 和 `AMAZON_ADS_MCP_URL`（如需） |

## Google Ads

你需要准备：

- Google Ads Customer ID：广告账户右上角或账户切换器里的 10 位数字。
- Developer Token：Google Ads Manager Account 的 API Center 里查看或申请。
- Google Cloud 凭证：用于只读访问 Google Ads API。
- Google Cloud Project ID。

你可以对 Agent 说：

```text
我选择了 Google Ads，帮我检查还缺哪些配置
```

Agent 会告诉你缺哪个字段，并把 Customer ID 写入 `config/accounts.json`。Google Cloud 登录这一步通常需要你在浏览器里点击授权，Agent 会在需要时提示。

官方参考：[Google Ads Developer Token](https://developers.google.com/google-ads/api/docs/api-policy/developer-token)。

## Meta Ads

你需要准备：

- Meta Ad Account ID，例如 `act_123456789`。
- 有广告账户查看权限的 Meta Business 用户。
- Meta Ads MCP OAuth 授权。

从哪里拿：

- Ad Account ID：Meta Ads Manager 的广告账户页面。
- OAuth：在 IDE 的 MCP 授权页面连接 Meta 官方 MCP。

对 Agent 说：

```text
我选择了 Meta Ads，帮我完成授权检查
```

Agent 会确认 `config/accounts.json` 里是否有广告账户 ID，并提示你在 IDE 里完成只读 OAuth。

官方参考：[Meta Ads AI connectors](https://www.facebook.com/business/help/1456422242197840)。

## Adjust

你需要准备：

- Adjust API Token。
- App 名称或 App Token。

从哪里拿：

- Adjust Dashboard 的个人资料或 API Token 页面。
- 如果公司开启 SSO，可能需要找管理员开通。

对 Agent 说：

```text
我选择了 Adjust，这是 API Token，帮我配置
```

Agent 会把 token 放到本地环境变量使用的位置，并把 App 信息写入 `config/accounts.json`。

官方参考：[Adjust Report service API authentication](https://dev.adjust.com/en/api/rs-api/authentication/)。

## AppsFlyer

你需要准备：

- AppsFlyer App ID。
- AppsFlyer MCP OAuth，或 AppsFlyer MCP Bearer Token。

从哪里拿：

- App ID：AppsFlyer 控制台的 App 页面。
- OAuth：IDE 的 MCP/OAuth 页面连接 AppsFlyer MCP。

对 Agent 说：

```text
我选择了 AppsFlyer，帮我检查 App ID 和授权
```

官方参考：[AppsFlyer MCP Help Center](https://support.appsflyer.com/hc/en-us/articles/36349070304785--Beta-AppsFlyer-MCP)。

## LinkedIn Ads

你需要准备：

- LinkedIn Ad Account ID。
- LinkedIn Marketing API / OAuth 读取权限。

从哪里拿：

- Ad Account ID：LinkedIn Campaign Manager 的广告账户页面。
- OAuth：按 LinkedIn MCP 或 Marketing API App 的授权流程完成。

对 Agent 说：

```text
我选择了 LinkedIn Ads，帮我检查账户 ID 和 OAuth
```

官方入口：[LinkedIn Marketing APIs](https://developer.linkedin.com/product-catalog/marketing)。

## Microsoft Advertising

你需要准备：

- Microsoft Advertising Account ID。
- Developer Token。
- Microsoft OAuth 授权。

从哪里拿：

- Account ID：Microsoft Advertising 后台账户页面。
- Developer Token：Microsoft Advertising Developer Portal。
- OAuth：对应 MCP 或 Microsoft Advertising API 授权流程。

对 Agent 说：

```text
我选择了 Microsoft Advertising，帮我检查凭证
```

官方参考：[Microsoft Advertising API Get Started](https://learn.microsoft.com/en-us/advertising/guides/get-started?view=bingads-13)、[Microsoft Advertising OAuth](https://learn.microsoft.com/en-us/advertising/guides/authentication-oauth?view=bingads-13)。

## Reddit Ads

你需要准备：

- Reddit Ads Account ID。
- Reddit Ads API OAuth。

从哪里拿：

- Account ID：Reddit Ads Manager。
- OAuth：Reddit Ads API 应用或对应 MCP 授权流程。

对 Agent 说：

```text
我选择了 Reddit Ads，帮我检查账户 ID 和授权
```

官方参考：[Reddit Advertising API Documentation](https://ads-api.reddit.com/docs/v3/)。

## TikTok Ads

你需要准备：

- TikTok Ads Advertiser ID。
- TikTok 官方 MCP / Agentic Hub 授权入口。
- 如果 IDE 需要 URL 配置，还需要官方提供的 MCP URL。

从哪里拿：

- Advertiser ID：TikTok Ads Manager / TikTok for Business 账户页面。
- MCP/OAuth：TikTok for Business 或 TikTok API for Business 官方入口。

对 Agent 说：

```text
我选择了 TikTok Ads，帮我检查 Advertiser ID 和 MCP URL
```

官方入口：[TikTok API for Business](https://business-api.tiktok.com/portal)。

## Amazon Ads

你需要准备：

- Amazon Ads Profile ID。
- Amazon Ads API credentials。
- 官方、伙伴或自托管 Amazon Ads MCP endpoint。

从哪里拿：

- API credentials：Amazon Ads Advanced Tools Center / Amazon Ads API。
- Profile ID：Amazon Ads API profiles 接口，代表某个 marketplace 下的广告账户。
- MCP endpoint：Amazon Ads MCP Server open beta 或合作伙伴提供的端点。

对 Agent 说：

```text
我选择了 Amazon Ads，帮我检查 Profile ID 和 MCP endpoint
```

官方参考：[Amazon Ads MCP Server open beta](https://advertising.amazon.com/library/news/amazon-ads-mcp-server-open-beta)、[Amazon Ads API getting started](https://advertising.amazon.com/API/docs/en-us/guides/get-started/overview)、[Retrieve profile ID](https://advertising.amazon.com/API/docs/en-us/guides/get-started/retrieve-profiles)。

## 配完后怎么验证

对 Agent 说：

```text
列出我已连接的平台账户
```

也可以只测某个平台：

```text
查看 Meta 广告账户列表
查询 AppsFlyer 昨日安装数据
查询 Amazon Ads 昨日 campaign 花费
```

如果报缺权限或未连接，回到对应平台的 OAuth / Token 配置即可，不需要重新做完整项目配置。
