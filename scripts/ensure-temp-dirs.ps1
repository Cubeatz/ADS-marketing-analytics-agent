param(
    [Parameter(Mandatory = $false)]
    [string]$Date = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd"),

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }

try {
    [Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $OutputEncoding = [Console]::OutputEncoding
    $env:PYTHONIOENCODING = "utf-8"
} catch { }

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $py) { Write-Error "需要 Python 运行 ensure-temp-dirs" }

& $py.Source (Join-Path $PSScriptRoot "ensure-temp-dirs.py") --date $Date --project-root $ProjectRoot
