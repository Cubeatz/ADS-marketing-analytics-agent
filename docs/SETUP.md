# 部署与配置指南

这份文档面向广告投放人员和协助他们的 Agent。普通用户不需要照着命令操作；你可以直接对 Agent 说：

```text
帮我完成首次配置
```

Agent 会自动完成环境检查、问卷、MCP 配置生成、目录创建和基础验证。只有平台 OAuth、API Token、账户 ID 这类必须登录广告后台获取的信息，需要你自己复制给 Agent 或填到本地配置里。

## Agent 会自动做什么

| 阶段 | Agent 自动处理 | 用户只需要做 |
|------|---------------|--------------|
| 环境检查 | 检查 Python、Node.js、pipx 和 DOCX 依赖 | 缺软件时按提示安装 |
| 首次问卷 | 询问平台、报告方式、数据目录、货币、飞书 | 根据实际业务回答 |
| 平台配置 | 生成 `config/workspace.json`、`config/accounts.json` 骨架 | 提供账户 ID、token 或 OAuth 授权 |
| MCP 安装 | 按 IDE 生成 MCP 配置 | 在需要 OAuth 的平台点击授权 |
| 报告目录 | 创建 `temp/`、`reports/`、`output/documents/` | 无需操作 |
| 验证 | 检查已选平台是否可连接 | 缺权限时补授权 |

## 平台凭证

只配置你在首次问卷第 1 题选择的平台；没选的平台可以跳过。

各平台凭证从哪里拿、填到哪里，见：[各平台凭证配置指南](PLATFORM-CREDENTIALS.md)。

常见例子：

- Google Ads：Customer ID、Developer Token、Google Cloud 登录凭证。
- Meta Ads：广告账户 ID 和 Meta MCP OAuth。
- Adjust：API Token。
- AppsFlyer：App ID 和 AppsFlyer MCP OAuth。
- TikTok Ads：Advertiser ID 和官方 MCP / Agentic Hub 授权。
- Amazon Ads：Profile ID、Amazon Ads API 凭证和 MCP endpoint。

## MCP 安装

用户可以直接说：

```text
帮我安装 MCP 到 Codex
```

或：

```text
帮我安装 MCP 到 Trae
```

Agent 会自动选择项目里的安装脚本，并按已启用平台生成配置。

部分 IDE（如 Trae、通义灵码/Qoder、MarsCode）没有稳定的本地配置路径，Agent 会生成可导入的 JSON，并告诉你在 IDE 的 MCP 设置页导入。

完整差异见：[IDE 支持矩阵](IDE-MATRIX.md)。

## 验证连接

配置完成后，对 Agent 说：

```text
列出我已连接的平台账户
```

也可以只验证某个平台：

```text
查看 Meta 广告账户列表
查询 AppsFlyer 昨日安装数据
查询 Adjust 昨日归因数据
```

未选择的平台不需要测试。

## 生成日报

对 Agent 说：

```text
生成昨日营销日报
```

未配置飞书时，Agent 会自动生成本地 Word 文档。配置了飞书 Webhook 时，Agent 会推送到飞书群。

## 常见问题

**必须装数据库吗？**

不需要。全部使用 JSON 配置、`temp/` 临时数据和 `reports/` 报告文件夹。

**为什么文档里提到 Google，但我没投 Google？**

Google Ads 只是一个可选平台。只有首次问卷选择 Google Ads 时，才需要 Google 相关凭证。

**暂不支持的平台怎么办？**

见 [平台支持清单](AD-PLATFORMS.md) 的“暂不支持”表。那里会说明是没有官方公开 MCP、只有第三方方案，还是处于封闭测试。

**没配飞书怎么办？**

不用配置。Agent 会自动生成本地 DOCX。

## 给技术维护者

项目脚本在 `scripts/` 目录，示例配置在 `config/*.example.json`，MCP 核心定义在 `integrations/mcp-servers.core.json`。这些是 Agent 自动化使用的入口，普通投放人员不需要直接运行。
