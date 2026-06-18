#!/usr/bin/env bash
set -euo pipefail

DATE="${1:-$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WS="$PROJECT_ROOT/config/workspace.json"

if [[ ! -f "$WS" ]]; then
  echo "请先运行: bash scripts/onboard.sh"
  exit 1
fi

completed=$(python3 -c "import json; print(json.load(open('$WS'))['onboarding'].get('completed', False))")
if [[ "$completed" != "True" ]]; then
  echo "请先完成 onboard 引导"
  exit 1
fi

mode=$(python3 -c "import json; print(json.load(open('$WS'))['delivery'].get('mode','local_docx'))")
reports_base=$(python3 -c "import json; print(json.load(open('$WS'))['directories'].get('reports_md','reports'))")
MD="$PROJECT_ROOT/$reports_base/$DATE/daily-report.md"

[[ -f "$MD" ]] || { echo "缺少 $MD"; exit 1; }

case "$mode" in
  feishu_webhook)
    if python3 -c "
import json
w=json.load(open('$WS'))
wh=w.get('feishu',{}).get('webhook',{})
url=(wh.get('url') or '').strip()
exit(0 if wh.get('enabled') and url and 'YOUR_WEBHOOK' not in url else 1)
"; then
      bash "$(dirname "$0")/send-feishu-daily.sh" "$DATE"
    else
      python3 "$PROJECT_ROOT/scripts/export-report-docx.py" --date "$DATE" --project-root "$PROJECT_ROOT"
    fi
    ;;
  local_md_only)
    echo "报告: $MD"
    ;;
  *)
    python3 "$PROJECT_ROOT/scripts/export-report-docx.py" --date "$DATE" --project-root "$PROJECT_ROOT"
    ;;
esac
