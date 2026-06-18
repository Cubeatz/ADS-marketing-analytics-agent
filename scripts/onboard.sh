#!/usr/bin/env bash
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

echo "启动逐题配置向导（支持“跳过”“上一步”）..."
"$PY" "$PARSE" --project-root "$PROJECT_ROOT" --interactive

DRAFT="$PROJECT_ROOT/config/onboarding-draft.json"
if [[ ! -f "$DRAFT" ]]; then
  echo "交互未完成" >&2
  exit 1
fi

"$PY" - "$PROJECT_ROOT" <<'PY'
import json
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path

root = Path(sys.argv[1])
draft = json.load(open(root / "config/onboarding-draft.json", encoding="utf-8"))
answers = draft["answers_compact"]
parse = root / "scripts/parse_onboarding_answers.py"
subprocess.run([sys.executable, str(parse), "--project-root", str(root), "--answers", answers], check=True)

ws = json.load(open(root / "config/workspace.json", encoding="utf-8"))
extras = {"answers_compact": answers}
back_words = {"上一步", "返回", "back", "上题"}
steps = []

def ask(prompt, default="", allow_back=True):
    hint = " [回车=跳过"
    if allow_back:
        hint += ", 上一步=返回"
    hint += "]"
    val = input(f"{prompt}{hint}: ").strip()
    if allow_back and val in back_words:
        return "__BACK__"
    return val or default

platforms = ws.get("platforms", {})
if platforms.get("google_ads", {}).get("enabled"):
    steps.append(("google_customer_id", "Google Ads Customer ID", ""))
if platforms.get("meta_ads", {}).get("enabled"):
    steps.append(("meta_ad_account_id", "Meta 广告账户 ID（如 act_123）", ""))
if platforms.get("adjust", {}).get("enabled"):
    print("Adjust：请配置环境变量 ADJUST_API_TOKEN")
if platforms.get("appsflyer", {}).get("enabled"):
    print("AppsFlyer：请在 IDE 中连接 MCP https://mcp.appsflyer.com/auth/mcp")
if platforms.get("linkedin_ads", {}).get("enabled"):
    steps.append(("linkedin_ad_account_id", "LinkedIn 广告账户 ID", ""))
if platforms.get("bing_ads", {}).get("enabled"):
    steps.append(("bing_account_id", "Microsoft Advertising 账户 ID", ""))
if platforms.get("reddit_ads", {}).get("enabled"):
    steps.append(("reddit_account_id", "Reddit Ads 账户 ID", ""))
if platforms.get("tiktok_ads", {}).get("enabled"):
    steps.append(("tiktok_advertiser_id", "TikTok Ads Advertiser ID", ""))
    print("TikTok Ads：如 IDE 需要 URL 配置，请设置 TIKTOK_ADS_MCP_URL")
if platforms.get("amazon_ads", {}).get("enabled"):
    steps.append(("amazon_ads_profile_id", "Amazon Ads Profile ID", ""))
    print("Amazon Ads：请准备 Amazon Ads API 凭证，并设置 AMAZON_ADS_MCP_URL")

steps.append(("app_name", "App 名称", "我的App"))
steps.append(("operator_name", "运营负责人姓名", ""))

if ws.get("schedule", {}).get("daily_report_time") == "custom" or "4D" in answers:
    steps.append(("custom_report_time", "自定义报告时间 HH:mm", "09:00"))

if ws.get("schedule", {}).get("usage_mode") == "one_time":
    yday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
    last3 = ",".join((datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d") for i in (1, 2, 3))
    scope = input(f"一次性使用：A 多天（默认前3天）/ B 单天（默认昨天） [A] > ").strip().upper()
    if scope == "B":
        extras["one_time_scope"] = "single"
        day = input(f"请输入单天日期 YYYY-MM-DD [{yday}] > ").strip()
        extras["one_time_single_date"] = day or yday
    else:
        extras["one_time_scope"] = "multi"
        days = input(f"请输入多天日期（逗号分隔）[{last3}] > ").strip()
        extras["one_time_multi_dates"] = days or last3

delivery = ws.get("delivery", {})
feishu = ws.get("feishu", {})
if delivery.get("mode") == "feishu_webhook" or feishu.get("webhook", {}).get("enabled"):
    steps.append(("feishu_webhook_url", "飞书 Webhook 地址", ""))

print("\n--- 补充账户信息（回车=跳过；输入“上一步”返回上一项）---")
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
subprocess.run([sys.executable, str(parse), "--project-root", str(root), "--answers", answers, "--extras-json", str(extras_path)], check=True)

thresh = root / "config/thresholds.json"
if not thresh.exists():
    import shutil
    shutil.copy(root / "config/thresholds.example.json", thresh)

sys.path.insert(0, str(root / "scripts"))
from workspace_lib import ensure_temp_layout, load_workspace, sync_legacy_feishu_json

ws = load_workspace(root)
sync_legacy_feishu_json(root, ws)
ensure_temp_layout(root, ws, datetime.now().strftime("%Y-%m-%d"))

print(f"\n配置完成！您的选择：{answers}")
print("下一步：bash scripts/install.sh <ide> -> MCP OAuth -> 说“生成昨日营销日报”")
PY
