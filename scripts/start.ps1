#Requires -Version 5.1
<#
.SYNOPSIS
  营销 Agent 一键首次启动：环境检查 → 配置向导 → MCP 安装提示

.DESCRIPTION
  非技术人员双击或在终端运行本脚本即可完成首次设置。
  环境齐全时检查步骤无输出；缺少 Python 时会提示安装并退出。

.PARAMETER Ide
  安装 MCP 的目标 IDE，默认 cursor。

.PARAMETER SkipInstall
  配置完成后跳过 MCP 安装（仅完成问卷与账户引导）。

.PARAMETER Answers
  非交互模式：直接传入问卷答案，如 "1AB 2A 3A 7A 8A 9A"。
#>
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [ValidateSet("cursor", "codex", "antigravity", "claude", "claude-desktop", "windsurf", "vscode", "gemini", "all")]
    [string]$Ide = "cursor",
    [string]$Answers = "",
    [switch]$SkipInstall,
    [switch]$Interactive
)

$ErrorActionPreference = "Stop"

function Test-OnboardingComplete {
    param([string]$Root)
    $wsPath = Join-Path $Root "config\workspace.json"
    if (-not (Test-Path $wsPath)) { return $false }
    try {
        $ws = Get-Content $wsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return [bool]$ws.onboarding.completed
    } catch {
        return $false
    }
}

function Find-PythonExe {
    $candidates = @()
    foreach ($name in @("python", "python3", "py")) {
        $candidates += Get-Command $name -All -ErrorAction SilentlyContinue
    }
    foreach ($path in @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe"
    )) {
        if (Test-Path $path) {
            $candidates += Get-Command $path -ErrorAction SilentlyContinue
        }
    }
    foreach ($cmd in $candidates) {
        if (-not $cmd) { continue }
        try {
            if ($cmd.Name -eq "py") {
                & $cmd.Source -3 -c "import sys" 2>$null | Out-Null
            } else {
                & $cmd.Source -c "import sys" 2>$null | Out-Null
            }
            if ($LASTEXITCODE -eq 0) { return $cmd.Source }
        } catch { }
    }
    return $null
}

function Install-PythonDependencies {
    param([string]$Root, [string]$PyExe)
    $req = Join-Path $Root "requirements.txt"
    if (-not (Test-Path $req)) { return }
    Write-Host "正在安装 Word 导出依赖 (python-docx)..." -ForegroundColor Cyan
    if ($PyExe -match "\\py\.exe$" -or (Split-Path -Leaf $PyExe) -eq "py") {
        & $PyExe -3 -m pip install -q -r $req
    } else {
        & $PyExe -m pip install -q -r $req
    }
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  已就绪" -ForegroundColor Green
    } else {
        Write-Host "  可稍后手动运行: pip install -r requirements.txt" -ForegroundColor Yellow
    }
}

function Show-NextSteps {
    param([string]$Root)
    $dataRoot = $Root
    $wsPath = Join-Path $Root "config\workspace.json"
    if (Test-Path $wsPath) {
        try {
            $ws = Get-Content $wsPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($ws.directories.workspace_root) {
                $dataRoot = $ws.directories.workspace_root
            }
        } catch { }
    }
    Write-Host ""
    Write-Host "========== 接下来您可以 ==========" -ForegroundColor Green
    Write-Host "1. 确认账户 ID：$dataRoot\config\accounts.json"
    Write-Host "2. 重启 Cursor，在 MCP 面板完成各平台 OAuth（只读授权即可）"
    Write-Host "3. Google Ads 还需设置环境变量，见 docs\SETUP.md"
    Write-Host "4. 在对话中说：「生成昨日营销日报」"
    Write-Host ""
}

Write-Host ""
Write-Host "营销数据分析 Agent — 首次启动" -ForegroundColor Cyan
Write-Host "项目路径: $ProjectRoot"
Write-Host ""

# 1. 环境检查（齐全则静默）
& "$PSScriptRoot\check-environment.ps1" -ProjectRoot $ProjectRoot -Quiet
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$pyExe = Find-PythonExe
if (-not $pyExe) {
    Write-Host "[必需] 未检测到可用的 Python，请先安装后再运行本脚本。" -ForegroundColor Red
    exit 1
}

# 2. 首次配置问卷
$needOnboard = -not (Test-OnboardingComplete -Root $ProjectRoot)
if ($needOnboard) {
    Write-Host ">>> 开始首次配置（约 2 分钟，支持「跳过」「上一步」）" -ForegroundColor Yellow
    Write-Host ""
    $onboardArgs = @("-ProjectRoot", $ProjectRoot)
    if ($Interactive -or [string]::IsNullOrWhiteSpace($Answers)) {
        $onboardArgs += "-Interactive"
    } else {
        $onboardArgs += @("-Answers", $Answers)
    }
    & "$PSScriptRoot\onboard.ps1" @onboardArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host "已完成首次配置，跳过问卷。" -ForegroundColor Green
    if (-not [string]::IsNullOrWhiteSpace($Answers)) {
        Write-Host "提示：若要修改配置，请运行 scripts\onboard.ps1 或删除 config\workspace.json 后重跑本脚本。" -ForegroundColor Yellow
    }
}

# 3. Python 依赖（Word 导出）
Install-PythonDependencies -Root $ProjectRoot -PyExe $pyExe

# 4. MCP 安装
if (-not $SkipInstall) {
    Write-Host ""
    $doInstall = Read-Host "是否现在安装广告平台 MCP 连接？(Y/n，推荐 Y)"
    if ($doInstall -match '^(|y|Y|yes|是)$') {
        Write-Host ""
        Write-Host ">>> 安装 MCP（IDE: $Ide）" -ForegroundColor Yellow
        & "$PSScriptRoot\install.ps1" -ProjectRoot $ProjectRoot -Ide $Ide
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    } else {
        Write-Host "已跳过 MCP 安装。稍后可运行: scripts\install.ps1 -Ide $Ide" -ForegroundColor Yellow
    }
} else {
    Write-Host "已跳过 MCP 安装（-SkipInstall）。" -ForegroundColor Yellow
}

Show-NextSteps -Root $ProjectRoot
Write-Host "全部完成。" -ForegroundColor Green
