#!/usr/bin/env bash
set -euo pipefail

IDE="${1:-all}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PY="${PYTHON:-python3}"
if ! command -v "$PY" >/dev/null 2>&1; then
  PY=python
fi

core_json() {
  local http_field="${1:-url}"
  "$PY" - "$PROJECT_ROOT" "$http_field" <<'PY'
import json, os, re, sys
from pathlib import Path

root = Path(sys.argv[1])
http_field = sys.argv[2]
text = (root / "integrations/mcp-servers.core.json").read_text(encoding="utf-8")
text = re.sub(r"\$\{(\w+)\}", lambda m: os.environ.get(m.group(1), m.group(0)), text)
core = json.loads(text)
mapping = {
    "google_ads": "google-ads",
    "meta_ads": "meta-ads",
    "adjust": "adjust",
    "appsflyer": "appsflyer",
    "linkedin_ads": "linkedin-ads",
    "bing_ads": "bing-ads",
    "reddit_ads": "reddit-ads",
    "tiktok_ads": "tiktok-ads",
    "amazon_ads": "amazon-ads",
}
selected = []
ws_path = root / "config/workspace.json"
if ws_path.exists():
    try:
        ws = json.loads(ws_path.read_text(encoding="utf-8"))
        if not (ws.get("onboarding") or {}).get("completed"):
            selected = list(mapping.values())
        else:
            selected = [mapping[k] for k, v in (ws.get("platforms") or {}).items() if v.get("enabled") and k in mapping]
    except Exception:
        pass
if not selected:
    selected = list(mapping.values())
servers = {}
for name in selected:
    srv = core["servers"].get(name)
    if not srv:
        continue
    if srv.get("transport") == "http":
        servers[name] = {http_field: srv["url"]}
    else:
        out = {"command": srv["command"], "args": srv.get("args", [])}
        if srv.get("env"):
            out["env"] = srv["env"]
        servers[name] = out
print(json.dumps({"mcpServers": servers}, ensure_ascii=False, indent=2))
PY
}

core_toml() {
  "$PY" - "$PROJECT_ROOT" <<'PY'
import json, os, re, sys
from pathlib import Path

root = Path(sys.argv[1])
text = (root / "integrations/mcp-servers.core.json").read_text(encoding="utf-8")
text = re.sub(r"\$\{(\w+)\}", lambda m: os.environ.get(m.group(1), m.group(0)), text)
core = json.loads(text)
mapping = {
    "google_ads": "google-ads",
    "meta_ads": "meta-ads",
    "adjust": "adjust",
    "appsflyer": "appsflyer",
    "linkedin_ads": "linkedin-ads",
    "bing_ads": "bing-ads",
    "reddit_ads": "reddit-ads",
    "tiktok_ads": "tiktok-ads",
    "amazon_ads": "amazon-ads",
}
selected = []
ws_path = root / "config/workspace.json"
if ws_path.exists():
    try:
        ws = json.loads(ws_path.read_text(encoding="utf-8"))
        if not (ws.get("onboarding") or {}).get("completed"):
            selected = list(mapping.values())
        else:
            selected = [mapping[k] for k, v in (ws.get("platforms") or {}).items() if v.get("enabled") and k in mapping]
    except Exception:
        pass
if not selected:
    selected = list(mapping.values())
lines = [
    "# 营销数据分析 MCP - Codex 配置片段",
    "# 由 scripts/install.sh 基于 integrations/mcp-servers.core.json 生成",
    "",
]
for name in selected:
    srv = core["servers"].get(name)
    if not srv:
        continue
    lines.append(f"[mcp_servers.{name}]")
    if srv.get("transport") == "http":
        lines.append(f'url = "{srv["url"]}"')
        lines.append("startup_timeout_sec = 30")
    else:
        args = ", ".join(json.dumps(x, ensure_ascii=False) for x in srv.get("args", []))
        lines.append(f'command = "{srv["command"]}"')
        lines.append(f"args = [{args}]")
        lines.append("startup_timeout_sec = 60")
        lines.append("tool_timeout_sec = 120")
        if srv.get("env"):
            lines.append("")
            lines.append(f"[mcp_servers.{name}.env]")
            for k, v in srv["env"].items():
                lines.append(f"{k} = {json.dumps(v, ensure_ascii=False)}")
    lines.append("")
print("\n".join(lines))
PY
}

ensure_configs() {
  for pair in "accounts.example.json:accounts.json" "thresholds.example.json:thresholds.json" "feishu.example.json:feishu.json" "workspace.example.json:workspace.json"; do
    src="${pair%%:*}"
    dst="${pair##*:}"
    if [[ ! -f "$PROJECT_ROOT/config/$dst" ]]; then
      cp "$PROJECT_ROOT/config/$src" "$PROJECT_ROOT/config/$dst"
      echo "  已创建 config/$dst"
    fi
  done
  mkdir -p "$PROJECT_ROOT/reports" "$PROJECT_ROOT/output/documents"
}

install_manual_json_ide() {
  local name="$1"
  local folder="$2"
  local hint="$3"
  local dir="$PROJECT_ROOT/integrations/$folder"
  mkdir -p "$dir"
  core_json url > "$dir/mcp.json"
  cat > "$dir/README.md" <<EOF
# $name MCP 配置

本脚本已生成可复制的 MCP JSON：

\`\`\`
$dir/mcp.json
\`\`\`

打开 $name 的 MCP / 工具 / 服务配置页面，手动粘贴 \`mcp.json\` 中的 \`mcpServers\` 配置，保存后重启 IDE，并完成所选平台的 OAuth / API Token 配置。

$hint

只读规则仍以项目根目录 \`AGENTS.md\` 为准。
EOF
  echo "  OK $dir/mcp.json"
}

run_ide() {
  case "$1" in
    cursor)
      mkdir -p "$PROJECT_ROOT/.cursor"
      core_json url > "$PROJECT_ROOT/.cursor/mcp.json"
      echo "  OK $PROJECT_ROOT/.cursor/mcp.json"
      ;;
    codex)
      mkdir -p "$PROJECT_ROOT/.codex" "$HOME/.codex"
      core_toml > "$PROJECT_ROOT/.codex/config.toml"
      if [[ ! -f "$HOME/.codex/config.toml" ]]; then
        cp "$PROJECT_ROOT/.codex/config.toml" "$HOME/.codex/config.toml"
      elif ! grep -q '\[mcp_servers.google-ads\]' "$HOME/.codex/config.toml"; then
        cat "$PROJECT_ROOT/.codex/config.toml" >> "$HOME/.codex/config.toml"
      fi
      [[ -f "$HOME/.codex/AGENTS.md" ]] || cp "$PROJECT_ROOT/AGENTS.md" "$HOME/.codex/AGENTS.md"
      echo "  OK Codex config"
      ;;
    antigravity)
      mkdir -p "$HOME/.gemini/antigravity"
      core_json serverUrl > "$HOME/.gemini/antigravity/mcp_config.json"
      echo "  OK $HOME/.gemini/antigravity/mcp_config.json"
      ;;
    claude)
      mkdir -p "$HOME/.claude"
      core_json url > "$HOME/.claude/settings.json"
      echo "  OK $HOME/.claude/settings.json"
      ;;
    claude-desktop)
      if [[ "$(uname)" == "Darwin" ]]; then
        dest="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
      else
        dest="${XDG_CONFIG_HOME:-$HOME/.config}/Claude/claude_desktop_config.json"
      fi
      mkdir -p "$(dirname "$dest")"
      core_json url > "$dest"
      echo "  OK $dest"
      ;;
    windsurf)
      mkdir -p "$HOME/.codeium/windsurf"
      core_json url > "$HOME/.codeium/windsurf/mcp_config.json"
      echo "  OK $HOME/.codeium/windsurf/mcp_config.json"
      ;;
    vscode)
      mkdir -p "$PROJECT_ROOT/.vscode"
      core_json url > "$PROJECT_ROOT/.vscode/mcp.json"
      echo "  OK $PROJECT_ROOT/.vscode/mcp.json"
      ;;
    gemini)
      mkdir -p "$HOME/.gemini"
      core_json httpUrl > "$HOME/.gemini/settings.json"
      echo "  OK $HOME/.gemini/settings.json"
      ;;
    trae)
      install_manual_json_ide "Trae" "trae" "Trae 官方 MCP 设置支持手动添加 MCP Server；Trae CN 通常在 AI 面板设置中的 MCP 页面导入。"
      ;;
    qoder|lingma)
      install_manual_json_ide "Qoder CN / 通义灵码" "qoder-cn" "Qoder CN / 通义灵码请在个人设置或智能体模式中的 MCP 服务页面添加。"
      ;;
    marscode)
      install_manual_json_ide "MarsCode" "marscode" "若当前 MarsCode 版本提供 MCP / 工具配置入口，请粘贴此 JSON；若没有 MCP 入口，请使用 VS Code / Trae / Qoder / Codex。"
      ;;
    *)
      echo "未知 IDE: $1" >&2
      exit 1
      ;;
  esac
}

echo "营销数据分析 Agent 安装"
echo "项目: $PROJECT_ROOT"
ensure_configs

if [[ "$IDE" == "all" ]]; then
  for i in cursor codex antigravity claude claude-desktop windsurf vscode gemini trae qoder marscode; do
    echo ">>> $i"
    run_ide "$i"
  done
else
  IFS=',' read -ra ides <<< "$IDE"
  for i in "${ides[@]}"; do
    i="$(echo "$i" | xargs)"
    [[ -z "$i" ]] && continue
    echo ">>> $i"
    run_ide "$i"
  done
fi

echo ""
echo "完成。请重启 IDE，并完成所选平台的 OAuth / API Token 配置。详见 docs/SETUP.md。"
