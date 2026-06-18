#Requires -Version 5.1
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Answers = "",
    [switch]$Interactive
)

$ErrorActionPreference = "Stop"

& "$PSScriptRoot\check-environment.ps1" -ProjectRoot $ProjectRoot -Quiet
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if (-not $py) { Write-Error "需要 Python" }

$parseScript = Join-Path $PSScriptRoot "parse_onboarding_answers.py"
$argsList = @("--project-root", $ProjectRoot)
$backPattern = '^(上一步|返回|back|上题)$'

function Read-WithNavigation {
    param(
        [string]$Prompt,
        [bool]$AllowBack = $true,
        [bool]$AllowSkip = $false,
        [string]$SkipDefault = ""
    )
    $suffix = ""
    if ($AllowBack) { $suffix += " [上一步]" }
    if ($AllowSkip) { $suffix += " [跳过]" }
    $val = Read-Host "$Prompt$suffix"
    if ($AllowBack -and $val -match $backPattern) { return @{ action = "back" } }
    if ($AllowSkip -and ($val -match '^(跳过|skip|z|Z)$' -or [string]::IsNullOrWhiteSpace($val))) {
        return @{ action = "skip"; value = $SkipDefault }
    }
    return @{ action = "value"; value = $val }
}

# --- 字母问卷 ---
$draftExtras = @{}
if ($Interactive -or [string]::IsNullOrWhiteSpace($Answers)) {
    & $py.Source $parseScript @argsList --interactive
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $draftPath = Join-Path $ProjectRoot "config\onboarding-draft.json"
    if (-not (Test-Path $draftPath)) { Write-Error "交互未完成" }
    $draft = Get-Content $draftPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Answers = $draft.answers_compact
    if ($draft.extras) {
        $draft.extras.PSObject.Properties | ForEach-Object { $draftExtras[$_.Name] = $_.Value }
    }
} else {
    while ($true) {
        $validateOut = & $py.Source $parseScript --project-root $ProjectRoot --answers $Answers.Trim() --validate-only 2>$null
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) { break }

        if ($exitCode -eq 4) {
            $payload = $null
            try { $payload = ($validateOut | Out-String) | ConvertFrom-Json } catch {}
            Write-Host ""
            if ($payload.message) { Write-Host $payload.message } else { Write-Host ($validateOut -join "`n") }
            Write-Host ""
            $dirChoice = Read-Host "继续(沿用此文件夹) / 换目录"
            if ($dirChoice -match '^(继续|沿用|是|1|y|yes)$') {
                $draftExtras["reuse_existing_workspace"] = $true
                & $py.Source $parseScript --project-root $ProjectRoot --answers $Answers.Trim() --validate-only --workspace-confirm reuse 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) { break }
            } else {
                $customPath = Read-Host "请输入新的文件夹完整路径"
                if (-not [string]::IsNullOrWhiteSpace($customPath)) {
                    $draftExtras["workspace_root_custom"] = $customPath
                }
                $draftExtras["reuse_existing_workspace"] = $false
                & $py.Source $parseScript --project-root $ProjectRoot --answers $Answers.Trim() --validate-only 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) { break }
            }
            continue
        }

        $errText = & $py.Source $parseScript --project-root $ProjectRoot --answers $Answers.Trim() --validate-only 2>&1
        Write-Host ""
        Write-Host ($errText -join "`n") -ForegroundColor Red
        Write-Host ""
        $Answers = Read-Host "请重新输入"
    }
}

$extras = @{ answers_compact = $Answers.Trim() }
foreach ($k in $draftExtras.Keys) { $extras[$k] = $draftExtras[$k] }

$extrasPath = Join-Path $ProjectRoot "config\onboarding-extras.json"
$extras | ConvertTo-Json | Set-Content $extrasPath -Encoding UTF8

$parseArgs = @(
    "--project-root", $ProjectRoot,
    "--answers", $Answers.Trim(),
    "--extras-json", $extrasPath
)
if ($extras["reuse_existing_workspace"] -eq $true) {
    $parseArgs += @("--workspace-confirm", "reuse")
}
& $py.Source $parseScript @parseArgs | Out-Null

$tmpWsPath = Join-Path $ProjectRoot "config\workspace.json"
$ws = Get-Content $tmpWsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$dataRoot = $ws.directories.workspace_root
if ([string]::IsNullOrWhiteSpace($dataRoot)) { $dataRoot = $ProjectRoot }

Write-Host ""
Write-Host "--- 补充账户信息（回车=跳过；输入「上一步」返回上一项）---" -ForegroundColor Yellow
Write-Host "数据目录：$dataRoot" -ForegroundColor DarkGray

$steps = [System.Collections.Generic.List[hashtable]]::new()
if ($ws.platforms.google_ads.enabled) {
    $steps.Add(@{ key = "google_customer_id"; prompt = "Google Ads Customer ID (10位数字)"; skip = "" })
}
if ($ws.platforms.meta_ads.enabled) {
    $steps.Add(@{ key = "meta_ad_account_id"; prompt = "Meta 广告账户 ID (如 act_123)"; skip = "" })
}
if ($ws.platforms.adjust.enabled) {
    Write-Host "Adjust：请在环境变量中配置 ADJUST_API_TOKEN" -ForegroundColor DarkGray
}
if ($ws.platforms.appsflyer.enabled) {
    Write-Host "AppsFlyer：请在 IDE 中连接 MCP https://mcp.appsflyer.com/auth/mcp" -ForegroundColor DarkGray
}
if ($ws.platforms.linkedin_ads.enabled) {
    $steps.Add(@{ key = "linkedin_ad_account_id"; prompt = "LinkedIn 广告账户 ID"; skip = "" })
}
if ($ws.platforms.bing_ads.enabled) {
    $steps.Add(@{ key = "bing_account_id"; prompt = "Microsoft Advertising 账户 ID"; skip = "" })
}
if ($ws.platforms.reddit_ads.enabled) {
    $steps.Add(@{ key = "reddit_account_id"; prompt = "Reddit Ads 账户 ID"; skip = "" })
}

$steps.Add(@{ key = "app_name"; prompt = "App 名称"; skip = "我的App" })
$steps.Add(@{ key = "operator_name"; prompt = "运营负责人姓名"; skip = "" })

if ($ws.schedule.usage_mode -eq "scheduled" -and ($ws.schedule.daily_report_time -eq "custom" -or $Answers -match "4D")) {
    $steps.Add(@{ key = "custom_report_time"; prompt = "自定义报告时间 HH:mm"; skip = "09:00" })
}

if ($ws.schedule.usage_mode -eq "one_time") {
    $yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
    $last3 = @(
        (Get-Date).AddDays(-1).ToString("yyyy-MM-dd"),
        (Get-Date).AddDays(-2).ToString("yyyy-MM-dd"),
        (Get-Date).AddDays(-3).ToString("yyyy-MM-dd")
    ) -join ","
    $scope = Read-Host "一次性使用：A 多天（推荐，默认前3天）/ B 单天（默认昨天） [A]"
    if ($scope -match '^[bB]$') {
        $extras["one_time_scope"] = "single"
        $day = Read-Host "请输入单天日期 YYYY-MM-DD [$yesterday]"
        if ([string]::IsNullOrWhiteSpace($day)) { $day = $yesterday }
        $extras["one_time_single_date"] = $day
    } else {
        $extras["one_time_scope"] = "multi"
        $days = Read-Host "请输入多天日期（逗号分隔）[$last3]"
        if ([string]::IsNullOrWhiteSpace($days)) { $days = $last3 }
        $extras["one_time_multi_dates"] = $days
    }
}

if ($ws.delivery.mode -eq "feishu_webhook" -or $ws.feishu.webhook.enabled) {
    $steps.Add(@{ key = "feishu_webhook_url"; prompt = "飞书 Webhook 地址"; skip = "" })
    $steps.Add(@{ key = "feishu_mention_all"; prompt = "@所有人? [y/N]"; skip = $false; is_bool = $true })
}

$idx = 0
while ($idx -lt $steps.Count) {
    $s = $steps[$idx]
    $allowBack = ($idx -gt 0)
    $r = Read-WithNavigation -Prompt $s.prompt -AllowBack $allowBack -AllowSkip $true -SkipDefault $s.skip
    if ($r.action -eq "back") {
        $idx = [Math]::Max(0, $idx - 1)
        continue
    }
    if ($r.action -eq "skip") {
        if ($s.is_bool) {
            $extras[$s.key] = $false
        } else {
            $extras[$s.key] = $s.skip
        }
    } elseif ($s.is_bool) {
        $extras[$s.key] = ($r.value -match '^[yY]')
    } else {
        $extras[$s.key] = $r.value
        if ([string]::IsNullOrWhiteSpace($extras[$s.key]) -and $s.skip) {
            $extras[$s.key] = $s.skip
        }
    }
    $idx++
}

$extras | ConvertTo-Json | Set-Content $extrasPath -Encoding UTF8

$finalArgs = @(
    "--project-root", $ProjectRoot,
    "--answers", $Answers.Trim(),
    "--extras-json", $extrasPath
)
if ($extras["reuse_existing_workspace"] -eq $true) {
    $finalArgs += @("--workspace-confirm", "reuse")
}
& $py.Source $parseScript @finalArgs | Out-Null

$ws = Get-Content $tmpWsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$dataRoot = $ws.directories.workspace_root
if ([string]::IsNullOrWhiteSpace($dataRoot)) { $dataRoot = $ProjectRoot }

# accounts.json -> 数据目录
$currency = $ws.preferences.currency_display
$tz = $ws.schedule.timezone
$accounts = @{
    apps = @(@{
        name = $extras["app_name"]
        enabled = $true
        google_ads = @{
            customer_id = $extras["google_customer_id"]
            login_customer_id = ""
            currency = $currency
            timezone = $tz
        }
        meta_ads = @{
            ad_account_id = $extras["meta_ad_account_id"]
            currency = $currency
            timezone = $tz
        }
        adjust = @{
            app_name = $extras["app_name"]
            api_token_env = "ADJUST_API_TOKEN"
        }
    })
    defaults = @{
        report_currency = $currency
        date_timezone = $tz
        attribution_window_days = 7
    }
}
New-Item -ItemType Directory -Force -Path (Join-Path $dataRoot "config") | Out-Null
$accounts | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $dataRoot "config\accounts.json") -Encoding UTF8

& $py.Source -c @"
import sys
sys.path.insert(0, r'$ProjectRoot\scripts')
from pathlib import Path
from workspace_lib import load_workspace, sync_legacy_feishu_json, ensure_temp_layout
from datetime import datetime
root = Path(r'$ProjectRoot')
ws = load_workspace(root)
sync_legacy_feishu_json(root, ws)
ensure_temp_layout(root, ws, datetime.now().strftime('%Y-%m-%d'))
"@

$thresh = Join-Path $dataRoot "config\thresholds.json"
if (-not (Test-Path $thresh)) {
    Copy-Item (Join-Path $ProjectRoot "config\thresholds.example.json") $thresh
}

Write-Host ""
Write-Host "配置完成！您的选择：$Answers" -ForegroundColor Green
Write-Host "数据目录：$dataRoot" -ForegroundColor Green
Write-Host "下一步：install.ps1 → MCP OAuth → 说「生成昨日营销日报」"
