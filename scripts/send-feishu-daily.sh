#!/usr/bin/env bash
# 飞书日报推送（macOS/Linux）
set -euo pipefail

DATE="${1:-$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FEISHU_CONFIG="$PROJECT_ROOT/config/feishu.json"
SUMMARY="$PROJECT_ROOT/reports/$DATE/data-summary.json"

[[ -f "$FEISHU_CONFIG" ]] || { echo "缺少 config/feishu.json"; exit 1; }
[[ -f "$SUMMARY" ]] || { echo "缺少 $SUMMARY，请先生成日报"; exit 1; }

python3 - "$FEISHU_CONFIG" "$SUMMARY" "$DATE" <<'PY'
import json, sys, urllib.request

feishu_path, summary_path, date = sys.argv[1:4]
feishu = json.load(open(feishu_path, encoding="utf-8"))
summary = json.load(open(summary_path, encoding="utf-8"))

if not feishu.get("enabled", True):
    print("飞书推送已禁用")
    sys.exit(0)

title = f"{feishu.get('report_title_prefix', '【营销日报】')} {date}"
lines = [f"**{title}**", "", "**总览**"]
for app in summary.get("apps", []):
    g, m, a, b = app.get("google", {}), app.get("meta", {}), app.get("appsflyer", {}), app.get("blended", {})
    lines.append(f"- **{app.get('name')}**：Google ${g.get('spend', 0)} | Meta ${m.get('spend', 0)} | AF {a.get('installs', 0)} 安装 | CPI ${b.get('cpi', 0)}")

lines += ["", "**预警**"]
alerts = summary.get("alerts") or []
lines.append("\n".join(f"- [{a['level']}] {a['message']}" for a in alerts) if alerts else "无")

lines += ["", "**建议**"]
actions = summary.get("action_items") or []
lines.append("\n".join(f"{i+1}. {x['text']}" for i, x in enumerate(actions)) if actions else "暂无")
lines.append(f"\n详细报告：reports/{date}/daily-report.md")

payload = json.dumps({"msg_type": "text", "content": {"text": "\n".join(lines)}}).encode()
req = urllib.request.Request(feishu["webhook_url"], data=payload, headers={"Content-Type": "application/json"})
with urllib.request.urlopen(req) as resp:
    print(resp.read().decode())
print(f"飞书推送完成：{date}")
PY
