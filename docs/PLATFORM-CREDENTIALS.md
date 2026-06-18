# 各平台配置从哪里来

这份文档告诉你：每个平台需要什么信息、从哪里拿、拿到后填到哪里。

先记住三条：

- 只配置你在首次问卷第 1 题选择的平台。
- 不要把 token、secret、webhook 发到聊天里，也不要提交到 GitHub。
- 能选权限时优先选择只读权限；本项目只做分析，不改广告账户。

## 配置位置速查

| 平台 | 你需要准备 | 从哪里来 | 填到哪里 |
|------|------------|----------|----------|
| Google Ads | Customer ID、Developer Token、Google Cloud ADC | Google Ads Manager 的 API Center；Google Cloud CLI 登录 | `config/accounts.json`；环境变量 |
| Meta Ads | Ad Account ID；OAuth 授权 | Meta Business / Ads Manager；IDE 的 MCP OAuth 页面 | `config/accounts.json`；IDE OAuth |
| Adjust | App 名称；API Token | Adjust Dashboard 用户资料/API Token 页面 | `config/accounts.json`；`ADJUST_API_TOKEN` |
| AppsFlyer | App ID；OAuth 或 MCP Token | AppsFlyer 控制台 / AppsFlyer MCP 授权 | `config/accounts.json`；IDE OAuth |
| LinkedIn Ads | Ad Account ID；OAuth 权限 | LinkedIn Campaign Manager / Marketing API App | `config/accounts.json`；对应 MCP OAuth |
| Microsoft Advertising | Account ID；Developer Token / OAuth | Microsoft Advertising UI / Developer Portal | `config/accounts.json`；对应 MCP OAuth |
| Reddit Ads | Account ID；OAuth | Reddit Ads Manager / Reddit Ads API App | `config/accounts.json`；对应 MCP OAuth |
| TikTok Ads | Advertiser ID；官方 MCP/OAuth 入口 | TikTok for Business / API for Business | `config/accounts.json`；`TIKTOK_ADS_MCP_URL`（如需） |
| Amazon Ads | Profile ID；Amazon Ads API 凭证；MCP 端点 | Amazon Ads Advanced Tools Center / Ads API | `config/accounts.json`；`AMAZON_ADS_MCP_URL`（如需） |

## Google Ads

你需要：

- Google Ads Customer ID
- Google Ads Developer Token
- Google Cloud Application Default Credentials
- Google Cloud Project ID

从哪里拿：

- Customer ID：打开 Google Ads 账户，右上角或账户切换器里能看到 10 位数字。
- Developer Token：使用 Google Ads Manager Account 登录，在 Tools / Billing / Settings 里的 API Center 查看或申请。
- ADC 凭证：安装 Google Cloud CLI 后运行登录命令。

配置方式：

```powershell
gcloud auth application-default login --scopes https://www.googleapis.com/auth/adwords,https://www.googleapis.com/auth/cloud-platform

$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\你\.config\gcloud\application_default_credentials.json"
$env:GOOGLE_PROJECT_ID = "你的GCP项目ID"
$env:GOOGLE_ADS_DEVELOPER_TOKEN = "你的Developer Token"
$env:GOOGLE_ADS_LOGIN_CUSTOMER_ID = "可选：经理账户ID"
```

同时在 `config/accounts.json` 填：

```json
{
  "google_ads": {
    "customer_id": "1234567890",
    "login_customer_id": "",
    "currency": "USD",
    "timezone": "America/Los_Angeles"
  }
}
```

官方参考：[Google Ads Developer Token](https://developers.google.com/google-ads/api/docs/api-policy/developer-token)。

## Meta Ads

你需要：

- Meta Ad Account ID，例如 `act_123456789`
- 有广告账户查看权限的 Meta Business 用户
- IDE 里的 Meta Ads MCP OAuth 授权

从哪里拿：

- Ad Account ID：打开 Meta Ads Manager，账户 ID 通常显示为 `act_...`。
- OAuth：在 IDE 的 MCP 设置中连接 Meta 官方 MCP URL。

配置方式：

```text
https://mcp.facebook.com/ads
```

在 `config/accounts.json` 填：

```json
{
  "meta_ads": {
    "ad_account_id": "act_123456789",
    "currency": "USD",
    "timezone": "America/Los_Angeles"
  }
}
```

官方参考：[Meta Ads AI connectors](https://www.facebook.com/business/help/1456422242197840)。

## Adjust

你需要：

- Adjust API Token
- App 名称或 App Token

从哪里拿：

- Adjust Dashboard 的个人资料/API Token 页面。
- 如果公司开启 SSO，可能需要联系管理员或 Adjust 支持。

配置方式：

```powershell
$env:ADJUST_API_TOKEN = "你的 Adjust API Token"
```

在 `config/accounts.json` 填：

```json
{
  "adjust": {
    "app_name": "你的App名称",
    "api_token_env": "ADJUST_API_TOKEN"
  }
}
```

官方参考：[Adjust Report service API authentication](https://dev.adjust.com/en/api/rs-api/authentication/)。

## AppsFlyer

你需要：

- AppsFlyer App ID
- AppsFlyer MCP OAuth，或 AppsFlyer MCP Bearer Token

从哪里拿：

- App ID：AppsFlyer 控制台的 App 页面。
- MCP OAuth：在 IDE 的 MCP/OAuth 页面连接 AppsFlyer MCP。

配置方式：

```text
https://mcp.appsflyer.com/auth/mcp
```

在 `config/accounts.json` 填：

```json
{
  "appsflyer": {
    "app_id": "id123456789",
    "android_package": "com.example.app",
    "ios_bundle_id": "com.example.app"
  }
}
```

官方参考：[AppsFlyer MCP Help Center](https://support.appsflyer.com/hc/en-us/articles/36349070304785--Beta-AppsFlyer-MCP)。

## LinkedIn Ads

你需要：

- LinkedIn Ad Account ID
- LinkedIn Marketing API / OAuth 权限

从哪里拿：

- Ad Account ID：LinkedIn Campaign Manager 的广告账户页面。
- OAuth：按你使用的 LinkedIn MCP 或 Marketing API App 完成授权。

配置方式：

在 `config/accounts.json` 填：

```json
{
  "linkedin_ads": {
    "ad_account_id": "123456789",
    "currency": "USD",
    "timezone": "America/Los_Angeles"
  }
}
```

权限建议：只读分析场景使用读取广告数据所需权限，不授权创建/修改广告的权限。

官方入口：[LinkedIn Marketing APIs](https://developer.linkedin.com/product-catalog/marketing)。

## Microsoft Advertising

你需要：

- Microsoft Advertising Account ID
- Developer Token
- Microsoft OAuth 授权

从哪里拿：

- Account ID：Microsoft Advertising 后台账户页面。
- Developer Token：Microsoft Advertising Developer Portal。
- OAuth：对应 MCP 或 Microsoft Advertising API 授权流程。

配置方式：

在 `config/accounts.json` 填：

```json
{
  "bing_ads": {
    "account_id": "123456789",
    "currency": "USD",
    "timezone": "America/Los_Angeles"
  }
}
```

官方参考：[Microsoft Advertising API Get Started](https://learn.microsoft.com/en-us/advertising/guides/get-started?view=bingads-13)、[Microsoft Advertising OAuth](https://learn.microsoft.com/en-us/advertising/guides/authentication-oauth?view=bingads-13)。

## Reddit Ads

你需要：

- Reddit Ads Account ID
- Reddit Ads API OAuth

从哪里拿：

- Account ID：Reddit Ads Manager。
- OAuth：创建 Reddit Ads API 应用并授权，或按你使用的 MCP 指引完成授权。

配置方式：

在 `config/accounts.json` 填：

```json
{
  "reddit_ads": {
    "account_id": "t2_example",
    "currency": "USD",
    "timezone": "America/Los_Angeles"
  }
}
```

官方参考：[Reddit Advertising API Documentation](https://ads-api.reddit.com/docs/v3/)。

## TikTok Ads

你需要：

- TikTok Ads Advertiser ID
- TikTok 官方 MCP / Agentic Hub 授权入口
- 如果 IDE 需要手动 URL，则需要官方提供的 MCP URL

从哪里拿：

- Advertiser ID：TikTok Ads Manager / TikTok for Business 账户页面。
- MCP/OAuth：TikTok for Business 或 TikTok API for Business 的官方入口。

配置方式：

如 IDE 需要 URL：

```powershell
$env:TIKTOK_ADS_MCP_URL = "官方提供的 MCP URL"
```

在 `config/accounts.json` 填：

```json
{
  "tiktok_ads": {
    "advertiser_id": "1234567890123456789",
    "currency": "USD",
    "timezone": "America/Los_Angeles"
  }
}
```

官方入口：[TikTok API for Business](https://business-api.tiktok.com/portal)。

## Amazon Ads

你需要：

- Amazon Ads Profile ID
- Amazon Ads API credentials
- 官方、伙伴或自托管 Amazon Ads MCP endpoint

从哪里拿：

- API credentials：Amazon Ads Advanced Tools Center / Amazon Ads API。
- Profile ID：通过 Amazon Ads API 的 profiles 接口获取；它代表某个 marketplace 下的广告账户。
- MCP endpoint：Amazon Ads MCP Server open beta 或合作伙伴提供的端点。

配置方式：

```powershell
$env:AMAZON_ADS_MCP_URL = "官方或伙伴提供的 MCP URL"
```

在 `config/accounts.json` 填：

```json
{
  "amazon_ads": {
    "profile_id": "1234567890",
    "currency": "USD",
    "timezone": "America/Los_Angeles"
  }
}
```

官方参考：[Amazon Ads MCP Server open beta](https://advertising.amazon.com/library/news/amazon-ads-mcp-server-open-beta)、[Amazon Ads API getting started](https://advertising.amazon.com/API/docs/en-us/guides/get-started/overview)、[Retrieve profile ID](https://advertising.amazon.com/API/docs/en-us/guides/get-started/retrieve-profiles)。

## 配完后怎么验证

1. 运行安装脚本：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Ide codex
```

2. 重启 IDE。

3. 在 IDE 里问 Agent：

```text
列出我已连接的平台账户
```

4. 只测试已选平台，例如：

```text
查看 Meta 广告账户列表
查询 AppsFlyer 昨日安装数据
查询 Amazon Ads 昨日 campaign 花费
```

如果报缺权限或未连接，先回到对应平台的 OAuth / Token 配置，不要重新跑完整项目。
