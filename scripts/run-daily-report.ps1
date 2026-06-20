param(
    [string]$ProjectRoot = "",
    [string]$Date = ""
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }

try {
    [Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $OutputEncoding = [Console]::OutputEncoding
    $env:PYTHONIOENCODING = "utf-8"
} catch { }

$wsPath = Join-Path $ProjectRoot "config\workspace.json"

if (-not (Test-Path $wsPath)) {
    Write-Error "请先运行 scripts\onboard.ps1 完成首次配置"
}

$ws = Get-Content $wsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$time = $ws.schedule.daily_report_time
$tz = $ws.schedule.timezone

function Get-ReportDates {
    param($Workspace, [string]$OverrideDate)

    if (-not [string]::IsNullOrWhiteSpace($OverrideDate)) {
        return @($OverrideDate -split "[,\s，]+" | Where-Object { $_ })
    }

    if ($Workspace.schedule.usage_mode -eq "one_time") {
        $window = $Workspace.schedule.one_time_window
        if ($window -and $window.dates) {
            return @($window.dates | ForEach-Object { [string]$_ })
        }
        return @((Get-Date).AddDays(-1).ToString("yyyy-MM-dd"))
    }

    return @((Get-Date).AddDays(-1).ToString("yyyy-MM-dd"))
}

function Invoke-EnsureTempDirs {
    param([string]$Root, [string]$ReportDate)

    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
    if (-not $py) {
        Write-Warning "未找到 Python，无法自动创建 temp 分类目录。"
        return
    }

    $script = Join-Path $PSScriptRoot "ensure-temp-dirs.py"
    if (Test-Path $script) {
        & $py.Source $script --date $ReportDate --project-root $Root | Out-Host
    }
}

if ($ws.schedule.usage_mode -eq "scheduled" -and $ws.schedule.weekdays_only) {
    $dow = (Get-Date).DayOfWeek
    if ($dow -eq "Saturday" -or $dow -eq "Sunday") {
        Write-Host "今日为周末，weekdays_only=true，跳过"
        exit 0
    }
}

$dates = @(Get-ReportDates -Workspace $ws -OverrideDate $Date)

Write-Host "开始生成营销日报（时区 $tz，计划时间 $time）..."
Write-Host "本次数据日期: $($dates -join ', ')"
foreach ($d in $dates) {
    Invoke-EnsureTempDirs -Root $ProjectRoot -ReportDate $d
}

if ($dates.Count -gt 1) {
    Write-Host "请在 IDE 中对 Agent 说：「按 workspace 配置生成这些日期的营销日报并逐日投递：$($dates -join ', ')」"
} else {
    $reportDate = @($dates)[0]
    Write-Host "请在 IDE 中对 Agent 说：「按 workspace 配置生成 $reportDate 的营销日报并投递」"
}
Write-Host ""
Write-Host "若已配置 MCP 全自动流程，Agent 将："
Write-Host "  1. ensure-temp-dirs → temp 分层子目录"
Write-Host "  2. 授权健康检查 → token 过期时尝试刷新/重连，最多 3 次"
Write-Host "  3. 三次失败则停止日报，并通知用户重新授权"
Write-Host "  4. 拉数 → temp/raw/{date}/{platform}/{category}/"
Write-Host "  5. 生成 reports/{date}/"
Write-Host "  6. 按 delivery.mode 投递"

# 计划任务占位：实际生成依赖 IDE Agent + MCP
# 可扩展为调用 headless 脚本
