#Requires -Version 5.1
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
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    gh auth status 2>&1 | Out-Null
    $authed = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = $prev
    if (-not $authed) {
        Write-Host ""
        Write-Host "[GitHub] Not logged in. Run first:" -ForegroundColor Yellow
        Write-Host "  gh auth login" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Complete browser auth, then run this script again." -ForegroundColor Yellow
        exit 1
    }
}

Set-Location $ProjectRoot
Require-GhAuth

$branch = git branch --show-current 2>$null
if (-not $branch) {
    Write-Host "No commits in this repo yet." -ForegroundColor Yellow
    exit 1
}

$null = git remote get-url $Remote 2>$null
$hasRemote = ($LASTEXITCODE -eq 0)

if (-not $hasRemote) {
    Write-Host ">>> Creating GitHub repo: $RepoName ($Visibility)" -ForegroundColor Cyan
    $createArgs = @("repo", "create", $RepoName, "--source", ".", "--remote", $Remote, "--$Visibility")
    if (-not $SkipPush) { $createArgs += "--push" }
    gh @createArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "Remote repository created and linked." -ForegroundColor Green
    if ($SkipPush) {
        Write-Host "Skipped push. Run: git push -u $Remote $branch" -ForegroundColor Yellow
    }
} elseif (-not $SkipPush) {
    Write-Host ">>> Pushing to $Remote/$branch" -ForegroundColor Cyan
    git push -u $Remote $branch
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$url = gh repo view --json url -q .url 2>$null
if ($url) {
    Write-Host ""
    Write-Host "GitHub repo: $url" -ForegroundColor Green
}
