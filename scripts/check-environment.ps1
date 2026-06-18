#Requires -Version 5.1
param(
    [string]$ProjectRoot = "",
    [ValidateSet("onboarding", "full")]
    [string]$Scope = "onboarding",
    [switch]$Quiet,
    [switch]$Json
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }

try {
    [Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $OutputEncoding = [Console]::OutputEncoding
    $env:PYTHONIOENCODING = "utf-8"
} catch { }

function Test-PythonRunnable {
    param([System.Management.Automation.CommandInfo]$Cmd)
    $exe = $Cmd.Source
    $name = $Cmd.Name
  try {
    if ($name -eq "py") {
      & $exe -3 -c "import sys" 2>$null | Out-Null
    } else {
      & $exe -c "import sys" 2>$null | Out-Null
    }
    return $LASTEXITCODE -eq 0
  } catch {
    return $false
  }
}

function Find-PythonCommand {
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
        if ($cmd -and (Test-PythonRunnable $cmd)) { return $cmd }
    }
    return $null
}

$py = Find-PythonCommand
if (-not $py) {
    if (-not $Json) {
        Write-Host ""
        Write-Host "[必需] 未检测到 Python 3.10+" -ForegroundColor Red
        Write-Host ""
        Write-Host "请先安装 Python，再继续首次配置:" -ForegroundColor Yellow
        Write-Host "  1. 打开 https://www.python.org/downloads/ 下载 Python 3.12"
        Write-Host '  2. 安装时勾选 Add python.exe to PATH'
        Write-Host '  3. 关闭并重新打开 Cursor 后，再运行 scripts/onboard.ps1'
        Write-Host ""
    }
    if ($Json) {
        @{ ok = $false; missing_required = @("python") } | ConvertTo-Json
    }
    exit 1
}

$checkScript = Join-Path $ProjectRoot "scripts\check_environment.py"
$argsList = @($checkScript, "--scope", $Scope)
if ($Quiet) { $argsList += "--quiet" }
if ($Json) { $argsList += "--json" }

& $py.Source @argsList
exit $LASTEXITCODE
