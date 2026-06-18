param(
    [Parameter(Mandatory = $false)]
    [string]$Date = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd"),

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $py) { Write-Error "需要 Python 运行 ensure-temp-dirs" }

& $py.Source (Join-Path $PSScriptRoot "ensure-temp-dirs.py") --date $Date --project-root $ProjectRoot
