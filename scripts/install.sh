#!/usr/bin/env bash
# 营销数据分析 Agent — macOS/Linux 安装脚本
set -euo pipefail

IDE="${1:-all}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

expand_env() {
  local file="$1"
  python3 - "$file" <<'PY'
import os, re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
def repl(m):
    return os.environ.get(m.group(1), m.group(0))
print(re.sub(r'\$\{(\w+)\}', repl, text), end="")
PY
}

core_json() {
  local http_field="${1:-url}"
  python3 - "$PROJECT_ROOT" "$http_field" <<'PY'
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
}
selected = []
ws_path = root / "config/workspace.json"
if ws_path.exists():
    try:
        ws = json.loads(ws_path.read_text(encoding="utf-8"))
        for key, cfg in (ws.get("platforms") or {}).items():
            if cfg.get("enabled") and key in mapping:
                selected.append(mapping[key])
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
  python3 - "$PROJECT_ROOT" <<'PY'
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
}
selected = []
ws_path = root / "config/workspace.json"
if ws_path.exists():
    try:
        ws = json.loads(ws_path.read_text(encoding="utf-8"))
        selected = [mapping[k] for k, v in (ws.get("platforms") or {}).items() if v.get("enabled") and k in mapping]
    except Exception:
        pass
if not selected:
    selected = list(mapping.values())
lines = [
    "# 营销数据分析 MCP — Codex 配置片段",
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

merge_json_mcp() {
  local target="$1"
  local template="$2"
  mkdir -p "$(dirname "$target")"
  local tmp
  tmp="$(mktemp)"
  expand_env "$template" > "$tmp"
  if [[ -f "$target" ]]; then
    python3 - "$target" "$tmp" <<'PY'
import json, sys
target, template = sys.argv[1], sys.argv[2]
with open(target) as f: cfg = json.load(f)
with open(template) as f: tpl = json.load(f)
cfg.setdefault("mcpServers", {})
cfg["mcpServers"].update(tpl.get("mcpServers", {}))
with open(target, "w") as f: json.dump(cfg, f, indent=2)
PY
  else
    cp "$tmp" "$target"
  fi
  rm -f "$tmp"
  echo "  OK $target"
}

ensure_configs() {
  for pair in "accounts.example.json:accounts.json" "thresholds.example.json:thresholds.json" "feishu.example.json:feishu.json"; do
    src="${pair%%:*}"
    dst="${pair##*:}"
    if [[ ! -f "$PROJECT_ROOT/config/$dst" ]]; then
      cp "$PROJECT_ROOT/config/$src" "$PROJECT_ROOT/config/$dst"
      echo "  已创建 config/$dst"
    fi
  done
  mkdir -p "$PROJECT_ROOT/reports"
}

install_cursor() {
  mkdir -p "$PROJECT_ROOT/.cursor"
  core_json url > "$PROJECT_ROOT/.cursor/mcp.json"
  echo "  OK $PROJECT_ROOT/.cursor/mcp.json"
}

install_codex() {
  mkdir -p "$PROJECT_ROOT/.codex" "$HOME/.codex"
  core_toml > "$PROJECT_ROOT/.codex/config.toml"
  if [[ ! -f "$HOME/.codex/config.toml" ]]; then
    cp "$PROJECT_ROOT/.codex/config.toml" "$HOME/.codex/config.toml"
  elif ! grep -q '\[mcp_servers.google-ads\]' "$HOME/.codex/config.toml"; then
    cat "$PROJECT_ROOT/.codex/config.toml" >> "$HOME/.codex/config.toml"
  fi
  [[ -f "$HOME/.codex/AGENTS.md" ]] || cp "$PROJECT_ROOT/AGENTS.md" "$HOME/.codex/AGENTS.md"
  echo "  OK Codex config"
}

install_antigravity() {
  mkdir -p "$HOME/.gemini/antigravity"
  core_json serverUrl > "$HOME/.gemini/antigravity/mcp_config.json"
  echo "  OK $HOME/.gemini/antigravity/mcp_config.json"
}

install_claude_desktop() {
  local dest
  if [[ "$(uname)" == "Darwin" ]]; then
    dest="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  else
    dest="${XDG_CONFIG_HOME:-$HOME/.config}/Claude/claude_desktop_config.json"
  fi
  mkdir -p "$(dirname "$dest")"
  core_json url > "$dest"
  echo "  OK $dest"
}

install_claude() {
  mkdir -p "$HOME/.claude"
  core_json url > "$HOME/.claude/settings.json"
  echo "  OK $HOME/.claude/settings.json"
}

install_windsurf() {
  mkdir -p "$HOME/.codeium/windsurf"
  core_json url > "$HOME/.codeium/windsurf/mcp_config.json"
  echo "  OK $HOME/.codeium/windsurf/mcp_config.json"
}

install_vscode() {
  mkdir -p "$PROJECT_ROOT/.vscode"
  core_json url > "$PROJECT_ROOT/.vscode/mcp.json"
  echo "  OK $PROJECT_ROOT/.vscode/mcp.json"
}

install_gemini() {
  mkdir -p "$HOME/.gemini"
  core_json httpUrl > "$HOME/.gemini/settings.json"
  echo "  OK $HOME/.gemini/settings.json"
}

run_ide() {
  case "$1" in
    cursor) install_cursor ;;
    codex) install_codex ;;
    antigravity) install_antigravity ;;
    claude) install_claude ;;
    claude-desktop) install_claude_desktop ;;
    windsurf) install_windsurf ;;
    vscode) install_vscode ;;
    gemini) install_gemini ;;
    *) echo "未知 IDE: $1"; exit 1 ;;
  esac
}

echo "营销数据分析 Agent 安装"
echo "项目: $PROJECT_ROOT"
ensure_configs

if [[ "$IDE" == "all" ]]; then
  for i in cursor codex antigravity claude claude-desktop windsurf vscode gemini; do
    echo ">>> $i"
    run_ide "$i"
  done
else
  run_ide "$IDE"
fi

echo ""
echo "完成。详见 docs/SETUP.md"
