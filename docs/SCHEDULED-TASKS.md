# 定时任务配置

如果你希望每天自动生成日报，直接对 Agent 说：

```text
帮我配置每天早上 9 点自动生成日报
```

Agent 会根据 `config/workspace.json` 的设置创建或指导创建系统计划任务。

## 前提

- 首次配置已完成。
- 已选平台的 MCP / OAuth / API Token 可用。
- 报告交付方式已确认：本地 Word、飞书 Webhook 或 Markdown。

## Agent 会做什么

| 步骤 | 行为 |
|------|------|
| 检查配置 | 确认 `schedule.auto_run`、报告时间、数据目录 |
| 授权健康检查 | 对已启用平台做轻量只读检查，确认 OAuth / token 可用 |
| 授权自动恢复 | 如 token 过期，尝试刷新或重新获取，最多 3 次 |
| 检查脚本 | 确认日报脚本可用 |
| 创建计划任务 | Windows 使用 Task Scheduler；macOS/Linux 使用对应系统任务方式 |
| 试跑 | 生成一份测试日报或验证脚本能启动 |
| 告知风险 | 提醒 OAuth token 过期时需要重新授权 |

## OAuth / Token 过期时

定时任务开始拉数前，Agent 必须先检查平台授权。

如果发现 token 过期或 OAuth 失效：

1. Agent 会尝试刷新或重新获取 token。
2. 最多尝试 3 次。
3. 每次失败都会记录到 `temp/logs/{date}/auth-check.log`。
4. 如果 3 次内恢复成功，继续生成日报。
5. 如果 3 次全部失败，停止正常日报，但生成空报告/失败报告。
6. 失败报告写入 `reports/{date}/auth-failed.md`，错误明细写入 `logs/{date}/auth-check.log` 和 `logs/{date}/errors.log`。
7. Agent 会告诉用户哪个平台需要重新授权；如果配置了飞书，会推送提醒。

注意：如果 refresh token 已失效、授权被撤销、用户改了密码，或管理员收回权限，平台通常要求用户重新登录授权，Agent 不能绕过这个限制。

## 需要用户介入的情况

有些系统会要求管理员权限或安全确认。遇到这种情况，Agent 会说明需要点击哪个确认按钮，或提示联系电脑管理员。

## 验证

配置完成后，对 Agent 说：

```text
检查自动日报是否配置成功
```

Agent 会检查计划任务是否存在、下次运行时间是否正确，以及最近一次运行日志。

## 日志保留

计划任务和 Agent 操作日志按天保存到 `logs/{date}/`，例如：

```text
logs/2026-06-20/run.log
logs/2026-06-20/auth-check.log
logs/2026-06-20/errors.log
logs/2026-06-20/delivery.log
```

默认只保留 30 天。Agent 每次创建当天日志目录时，会清理超过 `preferences.keep_logs_days` 的旧日志目录。
