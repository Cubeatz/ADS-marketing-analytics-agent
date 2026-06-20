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
$dataRoot = $ProjectRoot
if ($ws.directories -and -not [string]::IsNullOrWhiteSpace($ws.directories.workspace_root)) {
    $dataRoot = $ws.directories.workspace_root
}

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

function Write-RunLog {
    param([string]$Root, [string]$ReportDate, [string]$Message)
    $logDir = Join-Path $Root "logs\$ReportDate"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $line = "[{0}] {1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path (Join-Path $logDir "run.log") -Value $line -Encoding UTF8
}

function Remove-OldOperationLogs {
    param([string]$Root, [int]$KeepDays = 30)
    $logsRoot = Join-Path $Root "logs"
    if (-not (Test-Path $logsRoot)) { return }
    $cutoff = (Get-Date).Date.AddDays(-1 * $KeepDays)
    Get-ChildItem -Path $logsRoot -Directory | ForEach-Object {
        $parsed = [datetime]::MinValue
        if ([datetime]::TryParseExact($_.Name, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)) {
            if ($parsed.Date -lt $cutoff) {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
        }
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
    Write-RunLog -Root $dataRoot -ReportDate $d -Message "计划任务启动，数据日期 $d"
}

$keepLogsDays = 30
if ($ws.preferences.keep_logs_days) { $keepLogsDays = [int]$ws.preferences.keep_logs_days }
Remove-OldOperationLogs -Root $dataRoot -KeepDays $keepLogsDays

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
Write-Host "  3. 三次失败则生成空报告/失败报告，写入 logs/{date}/ 和 reports/{date}/，并通知用户重新授权"
Write-Host "  4. 拉数 → temp/raw/{date}/{platform}/{category}/"
Write-Host "  5. 生成 reports/{date}/"
Write-Host "  6. 按 delivery.mode 投递"

# 计划任务占位：实际生成依赖 IDE Agent + MCP
# 可扩展为调用 headless 脚本
