---
name: marketing-analytics
description: >-
  只读营销数据分析工作流：首次配置、MCP 安装、授权健康检查、广告/归因平台拉数、
  日报、素材疲劳、预算建议、归因对比、飞书推送或 DOCX 导出。
disable-model-invocation: false
---

# 营销数据分析 Skill

## 何时启用

- 用户说“首次配置”“初始化”“设置 agent”“帮我装好”
- `config/workspace.json` 不存在或 onboarding 未完成
- 用户请求营销日报、素材疲劳、预算建议、归因对比、飞书推送或 DOCX 报告
- 用户询问 OAuth token 是否过期、定时任务为什么失败、平台授权是否可用

## 交互原则

- 面向非技术用户时，Agent 自动运行脚本，不把命令丢给用户。
- 只有平台 OAuth、API Token、账户 ID、系统权限确认这类必须用户参与的环节，才请用户操作。
- 用户问平台凭证来源时，引用 `docs/PLATFORM-CREDENTIALS.md`。
- 用户问平台支持状态时，引用 `docs/AD-PLATFORMS.md`。

## 配置文件

| 文件 | 作用 |
|------|------|
| `config/workspace.json` | 总配置：平台、目录、时间、投递 |
| `config/accounts.json` | App 与各平台账户 ID |
| `config/field-mapping.json` | 跨平台指标字段对照 |
| `config/thresholds.json` | 分析阈值 |
| `config/feishu.json` | 飞书 Webhook |

## 首次引导

若 onboarding 未完成：

1. 自动检查环境。
2. 自动启动首次问卷。
3. 第 1 题只展示 `config/ad-platforms.json` 中已支持平台。
4. 根据用户选择生成 workspace 和 MCP 配置。
5. 缺少平台 OAuth / token 时，告诉用户去哪个后台获取。

当前支持平台：Google Ads、Meta Ads、Adjust、AppsFlyer、LinkedIn Ads、Microsoft Advertising、Reddit Ads、TikTok Ads、Amazon Ads。

## 授权健康检查

每次自动拉数、定时日报或批量日报前必须执行授权健康检查。

1. 对每个启用平台做轻量只读检查。
2. 遇到 token 过期、401/403、invalid_grant、OAuth required 等授权错误时，尝试刷新或重新获取 token。
3. 最多尝试 3 次。
4. 每次失败写入 `temp/logs/{date}/auth-check.log`。
5. 三次内成功则继续拉数。
6. 三次失败则停止日报，不生成假报告，并明确告诉用户需要重新授权的平台。
7. 有飞书 webhook 时推送提醒；否则写入 `reports/{date}/auth-failed.md`。

不能绕过平台 OAuth。Refresh token 失效、授权撤销、密码变化或管理员收回权限时，必须用户重新授权。

## 日报工作流

1. 检查 onboarding 已完成。
2. 创建当日 `temp/raw|processed|cache|logs|exports` 分层目录。
3. 执行授权健康检查。
4. 读取 workspace 和 accounts，对启用平台通过 MCP 只读拉数。
5. 原始 JSON 写入 `temp/raw/{date}/{platform}/{category}/`，禁止混放。
6. 清洗结果写入 `temp/processed/`，日志写入 `temp/logs/{date}/`。
7. 分析结果写入 `reports/{date}/`。
8. 按 delivery mode 投递飞书、Word 或 Markdown。

## 分析模块

### 素材疲劳

读取 `config/thresholds.json` 的 `creative_fatigue` 阈值。输出 ad 名称、投放天数、frequency、CTR 变化、疲劳等级和建议。

建议只能是文字建议，例如“考虑轮换素材 / 缩小受众 / 降低预算”，不得执行任何广告账户写操作。

### 预算建议

读取 `config/thresholds.json` 的 `budget` 阈值。输出预算不足、预算浪费、正常观察等判断，并说明依据。

### 归因差异

使用 `config/field-mapping.json` 对齐字段后，对比平台自报和 MMP 数据。说明可能原因，例如归因窗口、时区、SKAN 延迟、事件映射等。

## 输出质量

- 中文输出，非技术人员能读懂。
- 金额、比例保留 2 位小数。
- 每条建议说明依据。
- 不堆 API 字段原名，优先使用 `field-mapping.json` 中的 display name。
