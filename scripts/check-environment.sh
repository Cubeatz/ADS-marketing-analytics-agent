#!/usr/bin/env bash
# 检查营销 Agent 基础环境；齐全则静默通过
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCOPE="${1:-onboarding}"
QUIET="${QUIET:-1}"

PY="${PYTHON:-}"
if [[ -z "$PY" ]]; then
  for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
      PY="$candidate"
      break
    fi
  done
fi

if [[ -z "$PY" ]]; then
  echo ""
  echo "【必需】未检测到 Python 3.10+"
  echo ""
  echo "请先安装 Python，再继续首次配置："
  echo "  macOS: brew install python3"
  echo "  Linux: 使用系统包管理器安装 python3"
  echo "  然后重新运行: bash scripts/onboard.sh"
  echo ""
  exit 1
fi

ARGS=(--scope "$SCOPE")
[[ "$QUIET" == "1" ]] && ARGS+=(--quiet)

"$PY" "$PROJECT_ROOT/scripts/check_environment.py" "${ARGS[@]}"
