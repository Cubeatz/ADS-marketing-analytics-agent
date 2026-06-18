#!/usr/bin/env bash
# 营销 Agent 一键首次启动：环境检查 → 配置向导 → MCP 安装提示
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IDE="${IDE:-cursor}"
SKIP_INSTALL="${SKIP_INSTALL:-0}"
ANSWERS="${ANSWERS:-}"

usage() {
  echo "用法: bash scripts/start.sh [选项]"
  echo "  IDE=cursor|codex|all   安装 MCP 的目标 IDE（默认 cursor）"
  echo "  SKIP_INSTALL=1         跳过 MCP 安装"
  echo "  ANSWERS='1AB 2A ...'   非交互问卷答案"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

onboarding_done() {
  local ws="$PROJECT_ROOT/config/workspace.json"
  [[ -f "$ws" ]] || return 1
  python3 - "$ws" <<'PY' 2>/dev/null || return 1
import json, sys
ws = json.load(open(sys.argv[1], encoding="utf-8"))
sys.exit(0 if (ws.get("onboarding") or {}).get("completed") else 1)
PY
}

echo ""
echo "营销数据分析 Agent — 首次启动"
echo "项目路径: $PROJECT_ROOT"
echo ""

QUIET=1 bash "$(dirname "$0")/check-environment.sh" onboarding

PY="${PYTHON:-python3}"
command -v "$PY" >/dev/null 2>&1 || PY=python
command -v "$PY" >/dev/null 2>&1 || { echo "[必需] 未检测到 Python"; exit 1; }

if ! onboarding_done; then
  echo ">>> 开始首次配置（约 2 分钟，支持「跳过」「上一步」）"
  echo ""
  bash "$(dirname "$0")/onboard.sh"
else
  echo "已完成首次配置，跳过问卷。"
fi

if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
  echo "正在安装 Word 导出依赖 (python-docx)..."
  "$PY" -m pip install -q -r "$PROJECT_ROOT/requirements.txt" || \
    echo "  可稍后手动运行: pip install -r requirements.txt"
fi

if [[ "$SKIP_INSTALL" != "1" ]]; then
  echo ""
  read -r -p "是否现在安装广告平台 MCP 连接？(Y/n，推荐 Y) " reply
  if [[ -z "$reply" || "$reply" =~ ^([yY]|yes|是)$ ]]; then
    echo ""
    echo ">>> 安装 MCP（IDE: $IDE）"
    bash "$(dirname "$0")/install.sh" "$IDE"
  else
    echo "已跳过 MCP 安装。稍后可运行: bash scripts/install.sh $IDE"
  fi
fi

DATA_ROOT="$PROJECT_ROOT"
WS="$PROJECT_ROOT/config/workspace.json"
if [[ -f "$WS" ]]; then
  DATA_ROOT="$("$PY" -c "import json; print(json.load(open('$WS',encoding='utf-8')).get('directories',{}).get('workspace_root','') or '$PROJECT_ROOT')")"
fi

echo ""
echo "========== 接下来您可以 =========="
echo "1. 确认账户 ID：$DATA_ROOT/config/accounts.json"
echo "2. 重启 IDE，在 MCP 面板完成各平台 OAuth（只读授权即可）"
echo "3. Google Ads 还需设置环境变量，见 docs/SETUP.md"
echo "4. 在对话中说：「生成昨日营销日报」"
echo ""
echo "全部完成。"
