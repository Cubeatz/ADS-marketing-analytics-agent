# Windows 计划任务（可选）

若 `workspace.json` 中 `schedule.auto_run = true`，可用本机计划任务在指定时间自动生成日报。

## 前提

- 已完成 `scripts/onboard.ps1` 引导
- MCP 已连接且 OAuth 有效
- Python 与 `pip install -r requirements.txt` 已安装

## 创建每日任务（PowerShell 管理员）

将下面命令中的路径改为你的项目目录：

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\path\to\marketing-analytics-agent\scripts\run-daily-report.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
Register-ScheduledTask -TaskName "MarketingDailyReport" -Action $action -Trigger $trigger -Description "营销数据分析 Agent 自动生成日报"
```

## 手动试跑

```powershell
powershell -ExecutionPolicy Bypass -File scripts\run-daily-report.ps1
```

注意：计划任务运行时需已登录且 IDE/MCP OAuth token 未过期；部分 MCP 长期无交互可能需重新授权。
