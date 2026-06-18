#!/usr/bin/env bash
# 营销数据分析 Agent — 首次使用交互引导（macOS/Linux）
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUIET=1 bash "$(dirname "$0")/check-environment.sh" onboarding

PY="${PYTHON:-python3}"
if ! command -v "$PY" >/dev/null 2>&1; then
  PY=python
fi
if ! command -v "$PY" >/dev/null 2>&1; then
  echo "需要 Python 3" >&2
  exit 1
fi

PARSE="$PROJECT_ROOT/scripts/parse_onboarding_answers.py"

echo "启动逐题配置向导（支持「跳过」「上一步」）..."
"$PY" "$PARSE" --project-root "$PROJECT_ROOT" --interactive

DRAFT="$PROJECT_ROOT/config/onboarding-draft.json"
if [[ ! -f "$DRAFT" ]]; then
  echo "交互未完成" >&2
  exit 1
fi

"$PY" - "$PROJECT_ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
draft = json.load(open(root / "config/onboarding-draft.json", encoding="utf-8"))
answers = draft["answers_compact"]

parse = root / "scripts/parse_onboarding_answers.py"
import subprocess
subprocess.run([sys.executable, str(parse), "--project-root", str(root), "--answers", answers], check=True)

ws = json.load(open(root / "config/workspace.json", encoding="utf-8"))
extras = {"answers_compact": answers}

back_words = {"上一步", "返回", "back", "上题"}
steps = []

def ask(prompt, default="", allow_back=True):
    while True:
        hint = " [回车=跳过"
        if allow_back:
            hint += ", 上一步=返回"
        hint += "]"
        val = input(f"{prompt}{hint}: ").strip()
        if allow_back and val in back_words:
            return "__BACK__"
        if not val:
            return default
        return val

if ws["platforms"].get("google_ads", {}).get("enabled"):
    steps.append(("google_customer_id", "Google Ads Customer ID", ""))
if ws["platforms"].get("meta_ads", {}).get("enabled"):
    steps.append(("meta_ad_account_id", "Meta act_ 账户 ID", ""))
if ws["platforms"].get("adjust", {}).get("enabled"):
    print("Adjust：请配置环境变量 ADJUST_API_TOKEN")
if ws["platforms"].get("appsflyer", {}).get("enabled"):
    print("AppsFlyer：请在 IDE 连接 MCP https://mcp.appsflyer.com/auth/mcp")
steps.append(("app_name", "App 名称", "我的App"))
steps.append(("operator_name", "运营负责人姓名", ""))

if ws["schedule"].get("daily_report_time") == "custom" or "4D" in answers:
    steps.append(("custom_report_time", "自定义报告时间 HH:mm", "09:00"))

if ws.get("schedule", {}).get("usage_mode") == "one_time":
    from datetime import datetime, timedelta
    yday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
    d3 = ",".join((datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d") for i in (1, 2, 3))
    scope = input("一次性使用：A 多天（推荐，默认前3天）/ B 单天（默认昨天） [A] > ").strip().upper()
    if scope == "B":
        extras["one_time_scope"] = "single"
        day = input(f"请输入单天日期 YYYY-MM-DD [{yday}] > ").strip()
        extras["one_time_single_date"] = day or yday
    else:
        extras["one_time_scope"] = "multi"
        days = input(f"请输入多天日期（逗号分隔）[{d3}] > ").strip()
        extras["one_time_multi_dates"] = days or d3

delivery = ws.get("delivery", {})
feishu = ws.get("feishu", {})
if delivery.get("mode") == "feishu_webhook" or feishu.get("webhook", {}).get("enabled"):
    steps.append(("feishu_webhook_url", "飞书 Webhook 地址", ""))

print("\n--- 补充账户信息（回车=跳过；输入「上一步」返回上一项）---")
idx = 0
while idx < len(steps):
    key, prompt, default = steps[idx]
    val = ask(prompt, default, allow_back=(idx > 0))
    if val == "__BACK__":
        idx = max(0, idx - 1)
        continue
    extras[key] = val
    idx += 1

extras_path = root / "config/onboarding-extras.json"
json.dump(extras, open(extras_path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

subprocess.run(
    [sys.executable, str(parse), "--project-root", str(root), "--answers", answers, "--extras-json", str(extras_path)],
    check=True,
)

thresh = root / "config/thresholds.json"
if not thresh.exists():
    import shutil
    shutil.copy(root / "config/thresholds.example.json", thresh)

sys.path.insert(0, str(root / "scripts"))
from workspace_lib import load_workspace, sync_legacy_feishu_json, ensure_temp_layout
from datetime import datetime

sync_legacy_feishu_json(root, load_workspace(root))
ensure_temp_layout(root, load_workspace(root), datetime.now().strftime("%Y-%m-%d"))

print(f"\n配置完成！您的选择：{answers}")
print("下一步：bash scripts/install.sh <ide> → MCP OAuth → 说「生成昨日营销日报」")
PY
