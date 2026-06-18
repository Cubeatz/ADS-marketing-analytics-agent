param(
    [Parameter(Mandatory = $false)]
    [string]$Date = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd"),

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "",

    [Parameter(Mandatory = $false)]
    [switch]$ForceDocx
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }

try {
    [Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $OutputEncoding = [Console]::OutputEncoding
    $env:PYTHONIOENCODING = "utf-8"
} catch { }

function Get-WorkspaceConfig {
    param([string]$Root)
    $path = Join-Path $Root "config\workspace.json"
    if (-not (Test-Path $path)) { return $null }
    return Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Test-OnboardingComplete {
    param($Ws)
    if (-not $Ws) { return $false }
    return [bool]$Ws.onboarding.completed
}

function Get-FeishuConfig {
    param([string]$Root)
    $path = Join-Path $Root "config\feishu.json"
    if (-not (Test-Path $path)) {
        $example = Join-Path $Root "config\feishu.example.json"
        if (Test-Path $example) { return Get-Content $example -Raw -Encoding UTF8 | ConvertFrom-Json }
        return $null
    }
    return Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Test-FeishuConfigured {
    param($Cfg, $Ws)
    if ($Ws -and $Ws.feishu -and $Ws.feishu.webhook) {
        $wh = $Ws.feishu.webhook
        if (-not $wh.enabled) { return $false }
        $url = [string]$wh.url
    } elseif ($Cfg) {
        if (-not $Cfg.enabled) { return $false }
        $url = [string]$Cfg.webhook_url
    } else { return $false }
    if ([string]::IsNullOrWhiteSpace($url)) { return $false }
    $bad = @("YOUR_WEBHOOK", "YOUR_WEBHOOK_TOKEN", "example.com", "placeholder")
    foreach ($b in $bad) {
        if ($url -like "*$b*") { return $false }
    }
    return $true
}

function Get-ReportPaths {
    param($Root, $Ws, [string]$ReportDate)
    $reportsBase = if ($Ws -and $Ws.directories.reports_md) { $Ws.directories.reports_md } else { "reports" }
    $mdPath = Join-Path $Root (Join-Path $reportsBase "$ReportDate\daily-report.md")
    $summaryPath = Join-Path $Root (Join-Path $reportsBase "$ReportDate\data-summary.json")
    return @{ Md = $mdPath; Summary = $summaryPath }
}

function Invoke-DocxExport {
    param([string]$Root, [string]$ReportDate)
    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
    if (-not $py) { throw "未找到 Python，无法生成 DOCX。请运行: pip install -r requirements.txt" }

    $exportScript = Join-Path $PSScriptRoot "export-report-docx.py"
    $out = & $py.Source $exportScript --date $ReportDate --project-root $Root 2>&1
    if ($LASTEXITCODE -ne 0) { throw ($out -join "`n") }
    Write-Host "已生成 DOCX: $out"
    return [string]$out
}

$workspace = Get-WorkspaceConfig -Root $ProjectRoot
if (-not (Test-OnboardingComplete -Ws $workspace)) {
    Write-Error "请先完成首次配置: powershell -ExecutionPolicy Bypass -File scripts\onboard.ps1`n详见 docs/ONBOARDING.md"
}

$dateList = @($Date -split "[,\s，]+" | Where-Object { $_ })
if ($dateList.Count -gt 1) {
    $failed = 0
    foreach ($d in $dateList) {
        Write-Host ""
        Write-Host ">>> 投递日期 $d"
        if ($ForceDocx) {
            & $PSCommandPath -Date $d -ProjectRoot $ProjectRoot -ForceDocx
        } else {
            & $PSCommandPath -Date $d -ProjectRoot $ProjectRoot
        }
        if ($LASTEXITCODE -ne 0) { $failed += 1 }
    }
    if ($failed -gt 0) { exit 1 }
    exit 0
}

$paths = Get-ReportPaths -Root $ProjectRoot -Ws $workspace -ReportDate $Date
if (-not (Test-Path $paths.Md)) {
    Write-Error "缺少报告 $($paths.Md)，请先生成日报"
}

$feishu = Get-FeishuConfig -Root $ProjectRoot
$mode = if ($workspace.delivery.mode) { $workspace.delivery.mode } else { "local_docx" }

if ($ForceDocx) { $mode = "local_docx" }

switch ($mode) {
    "feishu_webhook" {
        if (Test-FeishuConfigured -Cfg $feishu -Ws $workspace) {
            if (-not (Test-Path $paths.Summary)) {
                Write-Warning "缺少 data-summary.json，将改为生成 DOCX"
            } else {
                & (Join-Path $PSScriptRoot "send-feishu-daily.ps1") -Date $Date -ProjectRoot $ProjectRoot
                exit $LASTEXITCODE
            }
        } else {
            Write-Warning "飞书 Webhook 未配置，降级为本地 DOCX"
            Invoke-DocxExport -Root $ProjectRoot -ReportDate $Date | Out-Null
        }
    }
    "feishu_document" {
        $doc = $workspace.feishu.document
        if ($doc -and $doc.enabled -and $doc.app_id) {
            Write-Warning "飞书云文档 API 需额外开发；当前降级为本地 DOCX + 可选 Webhook"
            $docxPath = Invoke-DocxExport -Root $ProjectRoot -ReportDate $Date
            if (Test-FeishuConfigured -Cfg $feishu -Ws $workspace) {
                & (Join-Path $PSScriptRoot "send-feishu-daily.ps1") -Date $Date -ProjectRoot $ProjectRoot
            }
            Write-Host "DOCX 已生成: $docxPath"
        } else {
            Write-Warning "飞书云文档未配置 app_id，降级为本地 DOCX"
            Invoke-DocxExport -Root $ProjectRoot -ReportDate $Date | Out-Null
        }
    }
    "local_md_only" {
        Write-Host "投递模式 local_md_only，报告已位于: $($paths.Md)"
    }
    default {
        Invoke-DocxExport -Root $ProjectRoot -ReportDate $Date | Out-Null
        Write-Host "已生成本地 Word 文档（见 workspace.directories.documents）"
    }
}
