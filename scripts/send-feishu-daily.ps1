param(
    [Parameter(Mandatory = $false)]
    [string]$Date = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd"),

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$feishuConfigPath = Join-Path $ProjectRoot "config\feishu.json"
$summaryPath = Join-Path $ProjectRoot "reports\$Date\data-summary.json"

if (-not (Test-Path $feishuConfigPath)) {
    Write-Error "缺少 config/feishu.json，请从 feishu.example.json 复制并填写 Webhook"
}

if (-not (Test-Path $summaryPath)) {
    Write-Error "缺少报告摘要 $summaryPath，请先生成日报"
}

$feishu = Get-Content $feishuConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$summary = Get-Content $summaryPath -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not $feishu.enabled) {
    Write-Host "飞书推送已禁用 (enabled=false)"
    exit 0
}

$title = "$($feishu.report_title_prefix) $Date"

$overviewLines = @()
foreach ($app in $summary.apps) {
    $overviewLines += "- **$($app.name)**：Google `$$($app.google.spend) | Meta `$$($app.meta.spend) | AF $($app.appsflyer.installs) 安装 | CPI `$$($app.blended.cpi)"
}

$alerts = @()
if ($summary.alerts) {
    foreach ($a in $summary.alerts) {
        $alerts += "- [$($a.level)] $($a.message)"
    }
}

$actions = @()
if ($summary.action_items) {
    $i = 1
    foreach ($item in $summary.action_items) {
        $actions += "$i. $($item.text)"
        $i++
    }
}

$bodyText = @(
    "**$title**",
    "",
    "**总览**",
    ($overviewLines -join "`n"),
    "",
    "**预警**",
    ($(if ($alerts.Count -gt 0) { $alerts -join "`n" } else { "无" })),
    "",
    "**建议**",
    ($(if ($actions.Count -gt 0) { $actions -join "`n" } else { "暂无" })),
    "",
    "详细报告：reports/$Date/daily-report.md"
) -join "`n"

$payload = @{
    msg_type = "text"
    content  = @{
        text = $bodyText
    }
} | ConvertTo-Json -Depth 5 -Compress

$response = Invoke-RestMethod -Uri $feishu.webhook_url -Method Post -Body $payload -ContentType "application/json; charset=utf-8"

if ($response.StatusCode -eq 0 -or $response.code -eq 0 -or $response.msg -eq "success") {
    Write-Host "飞书推送成功：$Date"
} else {
    Write-Host "飞书响应：$($response | ConvertTo-Json -Compress)"
}
