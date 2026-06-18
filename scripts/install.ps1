param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("cursor", "codex", "antigravity", "claude", "claude-desktop", "windsurf", "vscode", "gemini", "all")]
    [string]$Ide = "all",

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Expand-EnvPlaceholders {
    param([string]$Text)
    return [regex]::Replace($Text, '\$\{(\w+)\}', {
        param($m)
        $val = [Environment]::GetEnvironmentVariable($m.Groups[1].Value)
        if (-not $val) { $m.Value } else { $val }
    })
}

function Test-PythonRunnable {
    param([System.Management.Automation.CommandInfo]$Cmd)
    try {
        & $Cmd.Source -c "import sys" 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Find-PythonCommand {
    $candidates = @()
    $candidates += Get-Command python -All -ErrorAction SilentlyContinue
    $candidates += Get-Command python3 -All -ErrorAction SilentlyContinue
    $common = @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe"
    )
    foreach ($path in $common) {
        if (Test-Path $path) { $candidates += Get-Command $path -ErrorAction SilentlyContinue }
    }
    foreach ($cmd in $candidates) {
        if ($cmd -and (Test-PythonRunnable $cmd)) { return $cmd }
    }
    return $null
}

function Get-EnabledMcpServerNames {
    param([string]$Root)

    $map = @{
        google_ads   = "google-ads"
        meta_ads     = "meta-ads"
        adjust       = "adjust"
        appsflyer    = "appsflyer"
        linkedin_ads = "linkedin-ads"
        bing_ads     = "bing-ads"
        reddit_ads   = "reddit-ads"
    }

    $wsPath = Join-Path $Root "config\workspace.json"
    $selected = @()
    if (Test-Path $wsPath) {
        try {
            $ws = Get-Content $wsPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($ws.platforms) {
                $ws.platforms.PSObject.Properties | ForEach-Object {
                    if ($_.Value.enabled -and $map.ContainsKey($_.Name)) {
                        $selected += $map[$_.Name]
                    }
                }
            }
        } catch { }
    }

    if ($selected.Count -gt 0) { return $selected }
    return @("google-ads", "meta-ads", "adjust", "appsflyer", "linkedin-ads", "bing-ads", "reddit-ads")
}

function Convert-CoreServerToJsonShape {
    param($Server, [string]$HttpUrlField = "url")

    $out = [ordered]@{}
    if ($Server.transport -eq "http") {
        $out[$HttpUrlField] = $Server.url
    } else {
        $out.command = $Server.command
        $out.args = @($Server.args)
        if ($Server.env) { $out.env = $Server.env }
    }
    return $out
}

function New-CoreJsonTemplate {
    param(
        [string]$Root,
        [string]$HttpUrlField = "url"
    )

    $corePath = Join-Path $Root "integrations\mcp-servers.core.json"
    $core = Expand-EnvPlaceholders (Get-Content $corePath -Raw -Encoding UTF8) | ConvertFrom-Json
    $enabled = Get-EnabledMcpServerNames -Root $Root
    $servers = [ordered]@{}
    foreach ($name in $enabled) {
        $srv = $core.servers.$name
        if ($srv) {
            $servers[$name] = Convert-CoreServerToJsonShape -Server $srv -HttpUrlField $HttpUrlField
        }
    }
    return @{ mcpServers = $servers }
}

function Write-CoreJsonMcpServers {
    param(
        [string]$TargetPath,
        [string]$Root,
        [string]$HttpUrlField = "url",
        [switch]$Merge
    )

    $template = New-CoreJsonTemplate -Root $Root -HttpUrlField $HttpUrlField

    if ($Merge -and (Test-Path $TargetPath)) {
        $target = @{ mcpServers = @{} }
        $existing = Get-Content $TargetPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($existing.mcpServers) {
            $existing.mcpServers.PSObject.Properties | ForEach-Object {
                $target.mcpServers[$_.Name] = $_.Value
            }
        }
        $template.mcpServers.Keys | ForEach-Object {
            $target.mcpServers[$_] = $template.mcpServers[$_]
        }
        $template = $target
    }

    $dir = Split-Path $TargetPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $template | ConvertTo-Json -Depth 12 | Set-Content $TargetPath -Encoding UTF8
    Write-Host "  OK $TargetPath"
}

function Convert-CoreToToml {
    param([string]$Root)

    $corePath = Join-Path $Root "integrations\mcp-servers.core.json"
    $core = Expand-EnvPlaceholders (Get-Content $corePath -Raw -Encoding UTF8) | ConvertFrom-Json
    $enabled = Get-EnabledMcpServerNames -Root $Root
    $lines = @(
        "# 营销数据分析 MCP — Codex 配置片段",
        "# 由 scripts/install.ps1 基于 integrations/mcp-servers.core.json 生成",
        "# 环境变量在 [mcp_servers.*.env] 中引用，勿硬编码密钥",
        ""
    )
    foreach ($name in $enabled) {
        $srv = $core.servers.$name
        if (-not $srv) { continue }
        $lines += "[mcp_servers.$name]"
        if ($srv.transport -eq "http") {
            $lines += "url = " + (ConvertTo-TomlString ([string]$srv.url))
            $lines += "startup_timeout_sec = 30"
        } else {
            $args = @($srv.args) | ForEach-Object { ConvertTo-TomlString ([string]$_) }
            $lines += "command = " + (ConvertTo-TomlString ([string]$srv.command))
            $lines += "args = [$($args -join ', ')]"
            $lines += "startup_timeout_sec = 60"
            $lines += "tool_timeout_sec = 120"
            if ($srv.env) {
                $lines += ""
                $lines += "[mcp_servers.$name.env]"
                $srv.env.PSObject.Properties | ForEach-Object {
                    $lines += "$($_.Name) = $(ConvertTo-TomlString ([string]$_.Value))"
                }
            }
        }
        $lines += ""
    }
    return ($lines -join "`n")
}

function ConvertTo-TomlString {
    param([string]$Value)
    $slash = [string][char]92
    $quote = [string][char]34
    $escaped = $Value.Replace($slash, $slash + $slash).Replace($quote, $slash + $quote)
    return ([string][char]34) + $escaped + ([string][char]34)
}

function Merge-JsonMcpServers {
    param(
        [string]$TargetPath,
        [string]$TemplatePath,
        [hashtable]$ExtraKeys = @{}
    )
    $templateRaw = Expand-EnvPlaceholders (Get-Content $TemplatePath -Raw -Encoding UTF8)
    $template = $templateRaw | ConvertFrom-Json

    $target = @{ mcpServers = @{} }
    if (Test-Path $TargetPath) {
        $existing = Get-Content $TargetPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($existing.mcpServers) {
            $existing.mcpServers.PSObject.Properties | ForEach-Object {
                $target.mcpServers[$_.Name] = $_.Value
            }
        }
    }

    $template.mcpServers.PSObject.Properties | ForEach-Object {
        $target.mcpServers[$_.Name] = $_.Value
    }

    foreach ($k in $ExtraKeys.Keys) {
        if (-not $target.mcpServers.ContainsKey($k)) {
            $target.mcpServers[$k] = $ExtraKeys[$k]
        }
    }

    $dir = Split-Path $TargetPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

    @{ mcpServers = $target.mcpServers } | ConvertTo-Json -Depth 10 | Set-Content $TargetPath -Encoding UTF8
    Write-Host "  OK $TargetPath"
}

function Install-Cursor {
    $dest = Join-Path $ProjectRoot ".cursor\mcp.json"
    Write-CoreJsonMcpServers -TargetPath $dest -Root $ProjectRoot -HttpUrlField "url" -Merge
    Write-Host "Cursor: 规则已存在于 .cursor/rules/，重启 Cursor 后在 MCP 面板完成 OAuth"
}

function Install-Codex {
    $globalToml = Join-Path $env:USERPROFILE ".codex\config.toml"
    $projectToml = Join-Path $ProjectRoot ".codex\config.toml"
    $snippet = Convert-CoreToToml -Root $ProjectRoot

    New-Item -ItemType Directory -Force -Path (Split-Path $projectToml) | Out-Null
    Set-Content $projectToml $snippet -Encoding UTF8
    Write-Host "  OK $projectToml (项目级)"

    if (-not (Test-Path $globalToml)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $globalToml) | Out-Null
        Set-Content $globalToml $snippet -Encoding UTF8
        Write-Host "  OK $globalToml (全局，新建)"
    } else {
        $globalRaw = Get-Content $globalToml -Raw -Encoding UTF8
        if ($globalRaw -notmatch '\[mcp_servers\.google-ads\]') {
            Add-Content $globalToml "`n$snippet"
            Write-Host "  OK 已追加 MCP 片段到 $globalToml"
        } else {
            Write-Host "  跳过 $globalToml (已存在 google-ads 配置)"
        }
    }

    $agentsGlobal = Join-Path $env:USERPROFILE ".codex\AGENTS.md"
    if (-not (Test-Path $agentsGlobal)) {
        Copy-Item (Join-Path $ProjectRoot "AGENTS.md") $agentsGlobal -Force
        Write-Host "  OK 已复制 AGENTS.md 到 ~/.codex/"
    }
    Write-Host "Codex: 重启后运行 /mcp 验证"
}

function Install-Antigravity {
    $dest = Join-Path $env:USERPROFILE ".gemini\antigravity\mcp_config.json"
    Write-CoreJsonMcpServers -TargetPath $dest -Root $ProjectRoot -HttpUrlField "serverUrl" -Merge
    Write-Host "Antigravity: Agent 面板 -> Manage MCP Servers -> 完成 OAuth（注意用 serverUrl 字段）"
}

function Install-ClaudeDesktop {
    $dest = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"
    Write-CoreJsonMcpServers -TargetPath $dest -Root $ProjectRoot -HttpUrlField "url" -Merge
    Write-Host "Claude Desktop: 重启应用"
}

function Install-ClaudeCode {
    $dest = Join-Path $env:USERPROFILE ".claude\settings.json"
    if (-not (Test-Path $dest)) {
        @{ mcpServers = @{} } | ConvertTo-Json | Set-Content $dest -Encoding UTF8
    }
    Write-CoreJsonMcpServers -TargetPath $dest -Root $ProjectRoot -HttpUrlField "url" -Merge
    Write-Host "Claude Code: 重启 CLI"
}

function Install-Windsurf {
    $dest = Join-Path $env:USERPROFILE ".codeium\windsurf\mcp_config.json"
    Write-CoreJsonMcpServers -TargetPath $dest -Root $ProjectRoot -HttpUrlField "url" -Merge
    Write-Host "Windsurf: 重启 IDE"
}

function Install-Vscode {
    $dest = Join-Path $ProjectRoot ".vscode\mcp.json"
    Write-CoreJsonMcpServers -TargetPath $dest -Root $ProjectRoot -HttpUrlField "url"
    Write-Host "VS Code: 需 Copilot MCP 支持，重启 VS Code"
}

function Install-Gemini {
    $dest = Join-Path $env:USERPROFILE ".gemini\settings.json"
    if (-not (Test-Path $dest)) {
        @{ mcpServers = @{} } | ConvertTo-Json | Set-Content $dest -Encoding UTF8
    }
    Write-CoreJsonMcpServers -TargetPath $dest -Root $ProjectRoot -HttpUrlField "httpUrl" -Merge
    Write-Host "Gemini CLI: 重启 gemini"
}

function Ensure-ConfigFiles {
    $pairs = @(
        @("accounts.example.json", "accounts.json"),
        @("thresholds.example.json", "thresholds.json"),
        @("feishu.example.json", "feishu.json"),
        @("workspace.example.json", "workspace.json")
    )
    foreach ($p in $pairs) {
        $src = Join-Path $ProjectRoot "config\$($p[0])"
        $dst = Join-Path $ProjectRoot "config\$($p[1])"
        if (-not (Test-Path $dst)) {
            Copy-Item $src $dst
            Write-Host "  已创建 config/$($p[1])（请填写）"
        }
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $ProjectRoot "reports") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $ProjectRoot "output\documents") | Out-Null

    $py = Find-PythonCommand
    if ($py -and (Test-Path (Join-Path $ProjectRoot "config\workspace.example.json"))) {
        $d = (Get-Date).ToString("yyyy-MM-dd")
        & $py.Source (Join-Path $ProjectRoot "scripts\ensure-temp-dirs.py") --date $d --project-root $ProjectRoot 2>$null
    }

    $wsPath = Join-Path $ProjectRoot "config\workspace.json"
    if (Test-Path $wsPath) {
        $ws = Get-Content $wsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $ws.onboarding.completed) {
            Write-Host ""
            Write-Host ">>> 请先完成首次配置:" -ForegroundColor Yellow
            Write-Host "    powershell -ExecutionPolicy Bypass -File scripts\onboard.ps1" -ForegroundColor Yellow
        }
    }

    if ($py) {
        try {
            $oldEap = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            & $py.Source -m pip install -q -r (Join-Path $ProjectRoot "requirements.txt") 2>$null
            $ErrorActionPreference = $oldEap
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  已安装 DOCX 依赖 (python-docx)"
            } else {
                Write-Host "  提示: DOCX 依赖未自动安装，可稍后运行 python -m pip install -r requirements.txt"
            }
        } catch {
            $ErrorActionPreference = $oldEap
            Write-Host "  提示: DOCX 依赖未自动安装，可稍后运行 python -m pip install -r requirements.txt"
        }
    } else {
        Write-Host "  提示: 安装 Python/pip 后运行 pip install -r requirements.txt 以支持 DOCX 导出"
    }
}

Write-Host "营销数据分析 Agent 安装"
Write-Host "项目路径: $ProjectRoot"
Write-Host ""

Ensure-ConfigFiles

$ides = if ($Ide -eq "all") {
    @("cursor", "codex", "antigravity", "claude", "claude-desktop", "windsurf", "vscode", "gemini")
} else {
    $Ide -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

foreach ($i in $ides) {
    Write-Host ">>> 安装 $i"
    switch ($i) {
        "cursor"         { Install-Cursor }
        "codex"          { Install-Codex }
        "antigravity"    { Install-Antigravity }
        "claude"         { Install-ClaudeCode }
        "claude-desktop" { Install-ClaudeDesktop }
        "windsurf"       { Install-Windsurf }
        "vscode"         { Install-Vscode }
        "gemini"         { Install-Gemini }
    }
    Write-Host ""
}

Write-Host "Done. Set these environment variables, then restart the IDE:"
Write-Host "  GOOGLE_APPLICATION_CREDENTIALS"
Write-Host "  GOOGLE_PROJECT_ID"
Write-Host "  GOOGLE_ADS_DEVELOPER_TOKEN"
Write-Host "See docs/SETUP.md and docs/ONBOARDING.md"
