#Requires -Version 5.1
<#
.SYNOPSIS
  将本地 marketing-analytics-agent 关联到 GitHub 并推送（需已 gh auth login）

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\setup-github.ps1
  powershell -ExecutionPolicy Bypass -File scripts\setup-github.ps1 -Visibility public
#>
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RepoName = "marketing-analytics-agent",
    [ValidateSet("public", "private")]
    [string]$Visibility = "private",
    [string]$Remote = "origin",
    [switch]$SkipPush
)

$ErrorActionPreference = "Stop"

function Require-GhAuth {
    gh auth status 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "尚未登录 GitHub。请先运行：" -ForegroundColor Yellow
        Write-Host "  gh auth login" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "按提示在浏览器完成授权后，再重新运行本脚本。" -ForegroundColor Yellow
        exit 1
    }
}

Set-Location $ProjectRoot

Require-GhAuth

$branch = (git branch --show-current 2>$null)
if (-not $branch) {
    Write-Host "当前仓库还没有任何提交。请先运行：" -ForegroundColor Yellow
    Write-Host "  git add -A && git commit -m `"Initial commit`"" -ForegroundColor Cyan
    exit 1
}

$existingRemote = git remote get-url $Remote 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "远程 $Remote 已存在: $existingRemote" -ForegroundColor Green
} else {
    Write-Host ">>> 在 GitHub 创建仓库: $RepoName ($Visibility)" -ForegroundColor Cyan
    $createArgs = @("repo", "create", $RepoName, "--source", ".", "--remote", $Remote, "--$Visibility")
    if (-not $SkipPush) { $createArgs += "--push" }
    gh @createArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "已创建并关联远程仓库。" -ForegroundColor Green
    if ($SkipPush) {
        Write-Host "提示：已跳过推送，可运行 git push -u origin $branch" -ForegroundColor Yellow
    }
    exit 0
}

if (-not $SkipPush) {
    Write-Host ">>> 推送到 $Remote/$branch" -ForegroundColor Cyan
    git push -u $Remote $branch
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$url = gh repo view --json url -q .url 2>$null
if ($url) {
    Write-Host ""
    Write-Host "GitHub 仓库: $url" -ForegroundColor Green
}
