#!/usr/bin/env python3
"""解析「1AB 2A 3B」格式的引导答案，并生成 workspace 配置。"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Literal

# 同目录模块
sys.path.insert(0, str(Path(__file__).resolve().parent))
from workspace_lib import (  # noqa: E402
    default_workspace_root,
    detect_prior_usage,
    initialize_workspace_root,
)

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")


def load_json(project_root: Path, name: str) -> dict[str, Any]:
    with (project_root / "config" / name).open(encoding="utf-8") as f:
        return json.load(f)


def load_questions(project_root: Path) -> dict[str, Any]:
    return load_json(project_root, "onboarding-questions.json")


def load_ad_platforms(project_root: Path) -> dict[str, Any]:
    return load_json(project_root, "ad-platforms.json")


def supported_platforms(catalog: dict[str, Any]) -> list[dict[str, Any]]:
    return [p for p in (catalog.get("platforms") or []) if p.get("supported")]


def navigation_words(data: dict[str, Any]) -> tuple[list[str], list[str]]:
    nav = data.get("navigation") or {}
    back = nav.get("back") or ["上一步", "返回", "back", "上题"]
    skip = nav.get("skip") or ["跳过", "skip", "z", "Z"]
    return back, skip


def is_back_input(text: str, back_words: list[str]) -> bool:
    t = text.strip()
    return any(t.lower() == w.lower() for w in back_words)


def is_skip_input(text: str, skip_words: list[str]) -> bool:
    t = text.strip()
    return any(t.lower() == w.lower() for w in skip_words)


def usage_modes_config(data: dict[str, Any]) -> dict[str, Any]:
    return data.get("usage_modes") or {}


def usage_mode_from_state(
    state: dict[int, list[str]], questions: list[dict[str, Any]]
) -> str | None:
    letters = state.get(2)
    if not letters:
        return None
    q2 = next((q for q in questions if q.get("id") == 2), None)
    if not q2:
        return None
    opts = q2.get("options") or {}
    letter = letters[0]
    if letter in opts:
        return opts[letter]["value"]
    return None


def question_applies(q: dict[str, Any], usage_mode: str | None) -> bool:
    show_when = q.get("show_when")
    if not show_when:
        return True
    if not usage_mode:
        return False
    return usage_mode in show_when


def visible_question_ids(questions: list[dict[str, Any]], usage_mode: str | None) -> list[int]:
    return [q["id"] for q in questions if question_applies(q, usage_mode)]


def adjacent_visible_step(
    current: int,
    direction: int,
    state: dict[int, list[str]],
    questions: list[dict[str, Any]],
) -> int:
    usage = usage_mode_from_state(state, questions)
    ids = visible_question_ids(questions, usage)
    if current not in ids:
        return current
    idx = ids.index(current)
    nxt = idx + direction
    if 0 <= nxt < len(ids):
        return ids[nxt]
    if direction < 0 and nxt < 0:
        return ids[0]
    return ids[-1] + (1 if direction > 0 else 0)


def apply_usage_mode_defaults(resolved: dict[str, Any], data: dict[str, Any]) -> dict[str, Any]:
    mode = resolved.get("usage_mode") or "one_time"
    modes = usage_modes_config(data)
    cfg = modes.get(mode) or modes.get("one_time") or {}
    defaults = cfg.get("defaults") or {}
    if mode == "one_time":
        resolved.setdefault("report_time", defaults.get("report_time"))
        resolved.setdefault("weekdays_only", defaults.get("weekdays_only", False))
        resolved.setdefault("auto_run", defaults.get("auto_run", False))
    else:
        resolved.setdefault("report_time", defaults.get("report_time", "09:00"))
        resolved.setdefault("weekdays_only", defaults.get("weekdays_only", False))
        resolved.setdefault("auto_run", defaults.get("auto_run", True))
    return resolved


def default_yesterday_str() -> str:
    return (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")


def default_last_3_days() -> list[str]:
    base = datetime.now()
    return [(base - timedelta(days=i)).strftime("%Y-%m-%d") for i in (1, 2, 3)]


def parse_date_list(raw: str) -> list[str]:
    parts = [p.strip() for p in re.split(r"[,\s，]+", raw) if p.strip()]
    out: list[str] = []
    for part in parts:
        if re.fullmatch(r"\d{4}-\d{2}-\d{2}", part):
            out.append(part)
    return out


def resolve_one_time_window(extras: dict[str, Any]) -> dict[str, Any]:
    scope = (extras.get("one_time_scope") or "multi").strip().lower()
    if scope not in ("single", "multi"):
        scope = "multi"
    if scope == "single":
        day = (extras.get("one_time_single_date") or "").strip()
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", day):
            day = default_yesterday_str()
        return {"mode": "single", "dates": [day], "display": day}
    dates = parse_date_list((extras.get("one_time_multi_dates") or "").strip())
    if not dates:
        dates = default_last_3_days()
    return {"mode": "multi", "dates": dates, "display": ",".join(dates)}


def resolve_workspace_root_path(resolved: dict[str, Any], extras: dict[str, Any]) -> Path:
    custom = (extras.get("workspace_root_custom") or "").strip()
    if custom:
        return Path(custom).expanduser().resolve()
    loc = resolved.get("workspace_location") or "desktop_default"
    if loc == "custom":
        raise ValueError("第 7 题选了自定义路径，请提供文件夹完整路径。")
    return default_workspace_root()


def format_existing_workspace_message(root: Path, info: dict[str, Any]) -> str:
    lines = [
        f"检测到该文件夹已存在使用记录：",
        f"  {root}",
    ]
    for marker in info.get("markers") or []:
        lines.append(f"  · {marker}")
    lines.append("")
    lines.append("是否继续使用此文件夹？")
    lines.append("  · 「继续」/「是」— 沿用现有数据")
    lines.append("  · 「换目录」/「否」— 重新指定其他文件夹")
    return "\n".join(lines)


def workspace_nav_words(data: dict[str, Any]) -> tuple[list[str], list[str]]:
    nav = data.get("navigation") or {}
    reuse = nav.get("workspace_reuse") or ["继续", "沿用", "是", "1"]
    change = nav.get("workspace_change") or ["换目录", "否", "2"]
    return reuse, change


def is_workspace_reuse(text: str, words: list[str]) -> bool:
    t = text.strip()
    return any(t.lower() == w.lower() for w in words)


def is_workspace_change(text: str, words: list[str]) -> bool:
    t = text.strip()
    return any(t.lower() == w.lower() for w in words)


def platform_letter_map(catalog: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {p["letter"]: p for p in supported_platforms(catalog)}


def parse_compact_answers(text: str) -> dict[int, list[str]]:
    result: dict[int, list[str]] = {}
    text = text.strip().upper().replace(",", " ").replace("，", " ")
    for token in text.split():
        m = re.match(r"^(\d+)([A-Z]+)$", token)
        if not m:
            continue
        qid = int(m.group(1))
        letters = list(m.group(2))
        result[qid] = letters
    return result


def format_compact(parsed: dict[int, list[str]]) -> str:
    parts = []
    for qid in sorted(parsed.keys()):
        letters = "".join(parsed[qid])
        if letters:
            parts.append(f"{qid}{letters}")
    return " ".join(parts)


def parse_step_letters(raw: str, question: dict[str, Any]) -> list[str] | None:
    """解析单题输入；无效返回 None。"""
    text = raw.strip().upper().replace(",", "").replace(" ", "")
    if not text:
        return None
    if question.get("id") == 1:
        return list(text) if re.fullmatch(r"[A-Z]+", text) else None
    if question.get("type") == "multi":
        return list(text) if re.fullmatch(r"[A-Z]+", text) else None
    if len(text) == 1 and text.isalpha():
        return [text]
    return None


def validate_platform_letters(letters: list[str], catalog: dict[str, Any]) -> tuple[list[str], str | None]:
    """第1题仅校验是否属于已支持平台字母。"""
    by_letter = platform_letter_map(catalog)
    if not letters:
        return [], "第 1 题请至少选择一个平台，例如：A 或 AB"

    unknown = [letter for letter in letters if letter not in by_letter]
    if unknown:
        valid = ", ".join(sorted(by_letter.keys()))
        return [], f"第 1 题存在无效选项：{''.join(unknown)}。请只使用已支持平台字母：{valid}。"

    return [by_letter[letter]["id"] for letter in letters], None


def resolve_question(
    qid: int,
    letters: list[str],
    question: dict[str, Any],
    catalog: dict[str, Any],
) -> tuple[Any | None, str | None]:
    if qid == 1 and question.get("key") == "platforms":
        ids, err = validate_platform_letters(letters, catalog)
        if err:
            return None, err
        return ids, None

    if question.get("skippable") and letters == ["Z"]:
        default_letter = question.get("default_letter") or "A"
        opts = question.get("options") or {}
        if default_letter in opts:
            return opts[default_letter]["value"], None
        return question.get("skip_value"), None

    opts = question.get("options") or {}
    if question["type"] == "multi":
        invalid = [letter for letter in letters if letter not in opts]
        if invalid:
            valid = ", ".join(sorted(opts.keys()))
            return None, f"无效选项：{''.join(invalid)}。请使用 {valid}，或输入「跳过」/ Z。"
        return [opts[letter]["value"] for letter in letters], None

    letter = letters[0] if letters else None
    if not letter or letter not in opts:
        valid = ", ".join(sorted(opts.keys()))
        hint = "，或输入「跳过」/ Z" if question.get("skippable") else ""
        return None, f"请重新选择：{valid}{hint}（单选题选错须重选）"
    return opts[letter]["value"], None


def apply_skip_defaults(
    parsed: dict[int, list[str]],
    questions: list[dict[str, Any]],
    usage_mode: str | None = None,
) -> dict[int, list[str]]:
    """未作答的可跳过题自动视为 Z；不适用 usage_mode 的题不填充。"""
    out = dict(parsed)
    for q in questions:
        qid = q["id"]
        if not question_applies(q, usage_mode):
            out.pop(qid, None)
            continue
        if qid not in out and q.get("skippable"):
            out[qid] = ["Z"]
    return out


def resolve_answers(
    parsed: dict[int, list[str]],
    questions: list[dict],
    catalog: dict[str, Any],
    data: dict[str, Any] | None = None,
    *,
    fill_skips: bool = True,
) -> tuple[dict[str, Any], str | None]:
    usage_mode = None
    if 2 in parsed:
        q2 = next((q for q in questions if q.get("id") == 2), None)
        if q2:
            letter = parsed[2][0] if parsed[2] else None
            opts = q2.get("options") or {}
            if letter in opts:
                usage_mode = opts[letter]["value"]

    if fill_skips:
        parsed = apply_skip_defaults(parsed, questions, usage_mode)

    out: dict[str, Any] = {}
    qmap = {q["id"]: q for q in questions}

    for qid, letters in sorted(parsed.items()):
        q = qmap.get(qid)
        if not q:
            continue
        if not question_applies(q, usage_mode):
            continue
        value, err = resolve_question(qid, letters, q, catalog)
        if err:
            return {}, err
        out[q["key"]] = value

    if data:
        out = apply_usage_mode_defaults(out, data)

    return out, None


def validate_answers_payload(
    parsed: dict[int, list[str]],
    questions: list[dict],
    catalog: dict[str, Any],
    data: dict[str, Any],
    extras: dict[str, Any] | None = None,
    *,
    workspace_confirm: str | None = None,
) -> tuple[dict[str, Any] | None, int]:
    """返回 (json_payload, exit_code)。0=ok, 2=error, 4=目录确认。"""
    extras = extras or {}

    resolved, err = resolve_answers(
        parsed, questions, catalog, data, fill_skips=True
    )
    if err:
        return {"ok": False, "status": "error", "message": err}, 2

    try:
        root_path = resolve_workspace_root_path(resolved, extras)
    except ValueError as exc:
        return {"ok": False, "status": "error", "message": str(exc)}, 2

    loc = resolved.get("workspace_location") or "desktop_default"
    if (
        loc == "desktop_default"
        and workspace_confirm != "reuse"
        and extras.get("reuse_existing_workspace") is not True
    ):
        info = detect_prior_usage(root_path)
        if info.get("has_prior"):
            return {
                "ok": False,
                "status": "confirm_existing_workspace",
                "message": format_existing_workspace_message(root_path, info),
                "workspace_root": str(root_path),
                "markers": info.get("markers") or [],
            }, 4

    if workspace_confirm == "change":
        return {
            "ok": False,
            "status": "error",
            "message": "请提供新的文件夹路径（第 7 题选 B 或补充 workspace_root_custom）。",
        }, 2

    return {"ok": True, "resolved": resolved, "workspace_root": str(root_path)}, 0


def build_workspace(
    project_root: Path,
    resolved: dict[str, Any],
    extras: dict[str, Any],
    data: dict[str, Any] | None = None,
) -> tuple[dict[str, Any], Path]:
    example_path = project_root / "config" / "workspace.example.json"
    with example_path.open(encoding="utf-8") as f:
        example = json.load(f)

    if data:
        resolved = apply_usage_mode_defaults(dict(resolved), data)

    platforms_enabled = resolved.get("platforms") or []
    plats = example["platforms"]
    for key in plats:
        plats[key]["enabled"] = key in platforms_enabled
    if "google_ads" in plats:
        plats["google_ads"]["customer_id"] = extras.get("google_customer_id") or plats["google_ads"].get("customer_id", "")
    if "meta_ads" in plats:
        plats["meta_ads"]["ad_account_id"] = extras.get("meta_ad_account_id") or plats["meta_ads"].get("ad_account_id", "")
    if "linkedin_ads" in plats:
        plats["linkedin_ads"]["ad_account_id"] = extras.get("linkedin_ad_account_id") or plats["linkedin_ads"].get("ad_account_id", "")
    if "bing_ads" in plats:
        plats["bing_ads"]["account_id"] = extras.get("bing_account_id") or plats["bing_ads"].get("account_id", "")
    if "reddit_ads" in plats:
        plats["reddit_ads"]["account_id"] = extras.get("reddit_account_id") or plats["reddit_ads"].get("account_id", "")
    if "tiktok_ads" in plats:
        plats["tiktok_ads"]["advertiser_id"] = extras.get("tiktok_advertiser_id") or plats["tiktok_ads"].get("advertiser_id", "")
    if "amazon_ads" in plats:
        plats["amazon_ads"]["profile_id"] = extras.get("amazon_ads_profile_id") or plats["amazon_ads"].get("profile_id", "")

    delivery = resolved.get("delivery_mode") or "local_docx"
    usage_mode = resolved.get("usage_mode") or "one_time"
    modes = usage_modes_config(data or {})
    mode_cfg = modes.get(usage_mode) or {}
    data_period = (mode_cfg.get("defaults") or {}).get("data_period") or (
        "yesterday" if usage_mode == "scheduled" else "on_demand"
    )
    one_time_window = resolve_one_time_window(extras) if usage_mode == "one_time" else None

    report_time = resolved.get("report_time")
    if report_time == "custom":
        report_time = extras.get("custom_report_time") or "09:00"
    if usage_mode == "one_time":
        report_time = None

    workspace_root = resolve_workspace_root_path(resolved, extras)
    initialize_workspace_root(workspace_root, project_root)

    documents = "output/documents"

    feishu_ready = resolved.get("feishu_ready") or "none"
    wh_url = extras.get("feishu_webhook_url") or ""
    wh_enabled = delivery == "feishu_webhook" or feishu_ready == "webhook"
    if delivery in ("feishu_webhook", "feishu_document") and wh_url:
        wh_enabled = True

    doc_enabled = delivery == "feishu_document" or feishu_ready == "document"

    workspace = {
        "onboarding": {
            "completed": True,
            "completed_at": datetime.now().isoformat(timespec="seconds"),
            "operator_name": extras.get("operator_name") or "",
            "answers_compact": extras.get("answers_compact") or "",
            "platforms_selected": platforms_enabled,
            "usage_mode": usage_mode,
            "workspace_root": str(workspace_root),
            "notes": "由 parse_onboarding_answers 生成",
        },
        "platforms": plats,
        "schedule": {
            "usage_mode": usage_mode,
            "daily_report_time": report_time,
            "timezone": extras.get("timezone") or "Asia/Shanghai",
            "data_period": "custom_dates" if usage_mode == "one_time" else data_period,
            "one_time_window": one_time_window,
            "weekdays_only": bool(resolved.get("weekdays_only", False)),
            "auto_run": bool(resolved.get("auto_run", False)),
        },
        "directories": {
            "workspace_root": str(workspace_root),
            "reports_md": "reports",
            "documents": documents,
            "temp": example["directories"]["temp"],
        },
        "delivery": {
            "mode": delivery,
            "local_docx_filename": "daily-report.docx",
            "report_title_prefix": "【营销日报】",
        },
        "feishu": {
            "webhook": {
                "enabled": bool(wh_enabled and wh_url),
                "url": wh_url,
                "mention_all": bool(extras.get("feishu_mention_all", False)),
            },
            "document": {
                "enabled": bool(doc_enabled and extras.get("feishu_app_id")),
                "app_id": extras.get("feishu_app_id") or "",
                "app_secret": extras.get("feishu_app_secret") or "",
                "folder_token": extras.get("feishu_folder_token") or "",
            },
        },
        "preferences": {
            "language": "zh-CN",
            "currency_display": resolved.get("currency") or "USD",
            "keep_raw_days": 30,
            "keep_reports_days": 90,
            "keep_temp_days": 30,
            "alert_email": extras.get("alert_email") or "",
        },
    }
    return workspace, workspace_root


def print_nav_hints(question: dict[str, Any], step: int, back_words: list[str], skip_words: list[str]) -> None:
    hints: list[str] = []
    if step > 1:
        hints.append(f"输入「{back_words[0]}」返回上一题")
    if question.get("skippable"):
        hints.append(f"输入「{skip_words[0]}」或 Z = 选 A（推荐）")
    elif question.get("default_letter"):
        hints.append("默认推荐选 A")
    if hints:
        print("  提示：" + "；".join(hints))


def print_question(
    project_root: Path,
    q: dict[str, Any],
    catalog: dict[str, Any] | None = None,
    usage_mode: str | None = None,
) -> None:
    prompt = q.get("prompt") or ""
    print(f"{q['id']}. {prompt}")
    if q.get("id") == 1 and q.get("key") == "platforms":
        catalog = catalog or load_ad_platforms(project_root)
        for platform in supported_platforms(catalog):
            print(f"   {platform['letter']}. {platform['name']}（{platform.get('category', '')}）")
    elif q.get("key") == "workspace_location":
        default = default_workspace_root()
        for letter, opt in (q.get("options") or {}).items():
            label = opt["label"]
            if letter == "A" and str(default) not in label:
                label = f"{label} — {default}"
            print(f"   {letter}. {label}")
        if q.get("skippable"):
            print(f"   Z. 跳过（等同 A · {q.get('skip_hint', '桌面默认')}）")
    else:
        for letter, opt in (q.get("options") or {}).items():
            print(f"   {letter}. {opt['label']}")
        if q.get("skippable"):
            default_letter = q.get("default_letter") or "A"
            opts = q.get("options") or {}
            default_opt = opts.get(default_letter) or {}
            hint = default_opt.get("label") or q.get("skip_hint") or "选 A"
            print(f"   Z. 跳过（等同 A · {hint}）")
    print()

def print_questionnaire(project_root: Path) -> None:
    data = load_questions(project_root)
    catalog = load_ad_platforms(project_root)
    back_words, _ = navigation_words(data)
    print(data.get("instruction", ""))
    print()
    for q in data["questions"]:
        print_question(project_root, q, catalog)
    print("导航：")
    if back_words:
        print(f"  · 返回上一步：{' / '.join(back_words[:3])}")
    print("  · 跳过 / Z = 等同选 A（推荐项）")
    print("  · 第 2 题选「一次性」后，第 4–6 题（时间/工作日/自动运行）自动跳过")
    print("  · 第 7 题默认桌面 marketing-analytics-agent；若已有记录会询问是否沿用")


def prompt_workspace_reuse(data: dict[str, Any], root: Path, info: dict[str, Any]) -> Literal["reuse", "change", "back"] | None:
    reuse_words, change_words = workspace_nav_words(data)
    print(format_existing_workspace_message(root, info))
    print()
    while True:
        try:
            raw = input("目录确认 > ").strip()
        except (EOFError, KeyboardInterrupt):
            return None
        if is_workspace_reuse(raw, reuse_words):
            return "reuse"
        if is_workspace_change(raw, change_words):
            return "change"
        if is_back_input(raw, data.get("navigation", {}).get("back", [])):
            return "back"
        print("请输入「继续」沿用此文件夹，或「换目录」指定新路径。\n")


def prompt_one_time_window() -> dict[str, Any] | None:
    print("\n--- 一次性使用：数据日期范围 ---")
    print("A. 多天（推荐，默认前3天）")
    print("B. 单天（默认昨天）")
    try:
        scope = input("请选择 A/B [A] > ").strip().upper()
    except (EOFError, KeyboardInterrupt):
        return None
    if scope in ("", "A", "Z"):
        default_days = default_last_3_days()
        default_text = ",".join(default_days)
        try:
            raw = input(f"请输入日期（逗号分隔，YYYY-MM-DD）[{default_text}] > ").strip()
        except (EOFError, KeyboardInterrupt):
            return None
        parsed = parse_date_list(raw)
        return {
            "one_time_scope": "multi",
            "one_time_multi_dates": ",".join(parsed) if parsed else default_text,
        }
    if scope == "B":
        yday = default_yesterday_str()
        try:
            day = input(f"请输入日期（YYYY-MM-DD）[{yday}] > ").strip()
        except (EOFError, KeyboardInterrupt):
            return None
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", day):
            day = yday
        return {
            "one_time_scope": "single",
            "one_time_single_date": day,
        }
    print("输入无效，按默认处理为多天（前3天）。")
    return {
        "one_time_scope": "multi",
        "one_time_multi_dates": ",".join(default_last_3_days()),
    }


def run_interactive(project_root: Path) -> tuple[str, dict[str, Any], dict[str, Any]] | None:
    """逐题交互，返回 (compact_answers, resolved, extras) 或 None。"""
    data = load_questions(project_root)
    catalog = load_ad_platforms(project_root)
    questions = data["questions"]
    back_words, skip_words = navigation_words(data)
    max_id = max(q["id"] for q in questions)
    state: dict[int, list[str]] = {}
    extras: dict[str, Any] = {}
    step = 1

    print("=" * 50)
    print("  营销数据分析 Agent — 配置向导（逐题）")
    print("=" * 50)
    print(data.get("instruction", ""))
    print()

    while step <= max_id:
        usage = usage_mode_from_state(state, questions)
        if not question_applies(next(x for x in questions if x["id"] == step), usage):
            step += 1
            continue

        q = next(x for x in questions if x["id"] == step)
        print("-" * 40)
        if usage == "one_time" and q.get("show_when") == ["scheduled"]:
            step += 1
            continue

        print_question(project_root, q, catalog, usage)
        print_nav_hints(q, step, back_words, skip_words)
        if step == 2:
            print("  提示：选 A「一次性」将跳过后面的报告时间与自动运行题目\n")
        try:
            raw = input(f"第 {step} 题 > ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n已取消。")
            return None

        if is_back_input(raw, back_words):
            if step > 1:
                prev = adjacent_visible_step(step, -1, state, questions)
                if state.get(step):
                    state.pop(step, None)
                step = prev
                print(f"\n已返回第 {step} 题。\n")
            else:
                print("\n已是第一题，无法返回。\n")
            continue

        if is_skip_input(raw, skip_words):
            if q.get("skippable"):
                state[step] = ["Z"]
                print(f"  → 已跳过，等同选 A（推荐）\n")
                step = adjacent_visible_step(step, 1, state, questions)
                if step > max_id:
                    break
                continue
            print("\n第 1 题（平台）不可跳过，请至少选一个已支持平台。\n")
            continue

        letters = parse_step_letters(raw, q)
        if not letters:
            print("\n输入无效。请按提示选择字母，或使用「跳过」「上一步」。\n")
            continue

        _, err = resolve_question(step, letters, q, catalog)
        if err:
            print(f"\n{err}\n")
            continue

        state[step] = letters

        if step == 7:
            resolved_partial, _ = resolve_answers(state, questions, catalog, data, fill_skips=False)
            try:
                root_path = resolve_workspace_root_path(resolved_partial, extras)
            except ValueError as exc:
                print(f"\n{exc}\n")
                continue
            loc = resolved_partial.get("workspace_location") or "desktop_default"
            if loc == "desktop_default":
                info = detect_prior_usage(root_path)
                if info.get("has_prior"):
                    ws_choice = prompt_workspace_reuse(data, root_path, info)
                    if ws_choice is None:
                        return None
                    if ws_choice == "back":
                        state.pop(7, None)
                        print("\n请重新选择目录。\n")
                        continue
                    if ws_choice == "reuse":
                        extras["reuse_existing_workspace"] = True
                    else:
                        state[7] = ["B"]
                        try:
                            custom = input("请输入新的文件夹完整路径 > ").strip()
                        except (EOFError, KeyboardInterrupt):
                            return None
                        if not custom:
                            print("\n路径不能为空。\n")
                            state.pop(7, None)
                            continue
                        extras["workspace_root_custom"] = custom
            elif loc == "custom":
                try:
                    custom = input("请输入文件夹完整路径 > ").strip()
                except (EOFError, KeyboardInterrupt):
                    return None
                if not custom:
                    print("\n路径不能为空。\n")
                    state.pop(7, None)
                    continue
                extras["workspace_root_custom"] = custom

        step = adjacent_visible_step(step, 1, state, questions)
        if step > max_id:
            break

    compact = format_compact(state)
    resolved, err = resolve_answers(state, questions, catalog, data, fill_skips=True)
    if err:
        print(err, file=sys.stderr)
        return None
    if resolved.get("usage_mode") == "one_time":
        one_time = prompt_one_time_window()
        if one_time is None:
            return None
        extras.update(one_time)
    return compact, resolved, extras


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=None)
    parser.add_argument("--show", action="store_true", help="仅显示问卷")
    parser.add_argument("--interactive", "-i", action="store_true", help="逐题交互（支持跳过/上一步）")
    parser.add_argument("--validate-only", action="store_true", help="仅校验答案")
    parser.add_argument("--answers", help='紧凑答案，如 "1AB 2A 3A 7A 8A 9A"（Z=等同A）')
    parser.add_argument(
        "--workspace-confirm",
        choices=["reuse", "change"],
        help="桌面目录已有记录时：reuse=沿用，change=换目录",
    )
    parser.add_argument("--extras-json", help="后续字段 JSON 文件路径")
    args = parser.parse_args()

    root = Path(args.project_root) if args.project_root else Path(__file__).resolve().parent.parent
    catalog = load_ad_platforms(root)
    data = load_questions(root)

    if args.show:
        print_questionnaire(root)
        return 0

    if args.interactive:
        result = run_interactive(root)
        if not result:
            return 1
        compact, resolved, extras = result
        extras["answers_compact"] = compact
        print("\n您的选择（紧凑格式）：")
        print(f"  {compact}")
        print(json.dumps({"resolved": resolved, "workspace_root": str(resolve_workspace_root_path(resolved, extras))}, ensure_ascii=False, indent=2))
        draft_path = root / "config" / "onboarding-draft.json"
        with draft_path.open("w", encoding="utf-8") as f:
            json.dump({"answers_compact": compact, "resolved": resolved, "extras": extras}, f, ensure_ascii=False, indent=2)
        print(f"\n已保存草稿：{draft_path}")
        return 0

    if not args.answers:
        print_questionnaire(root)
        print("请回复示例：1AB 2A 3A 7A 8A 9A（Z 等同选 A）")
        print("或运行：python scripts/parse_onboarding_answers.py --interactive")
        return 0

    parsed = parse_compact_answers(args.answers)

    extras: dict[str, Any] = {"answers_compact": args.answers}
    if args.extras_json and Path(args.extras_json).exists():
        extras.update(json.load(open(args.extras_json, encoding="utf-8")))
    if args.workspace_confirm == "reuse":
        extras["reuse_existing_workspace"] = True

    ws_confirm = args.workspace_confirm
    if ws_confirm == "reuse":
        ws_confirm = "reuse"
    elif ws_confirm == "change":
        ws_confirm = "change"

    payload, code = validate_answers_payload(
        parsed,
        data["questions"],
        catalog,
        data,
        extras,
        workspace_confirm=ws_confirm,
    )

    if args.validate_only:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return code

    if code != 0:
        msg = payload.get("message") if payload else "校验失败"
        print(msg or "校验失败", file=sys.stderr)
        return code

    resolved = payload["resolved"]
    extras["answers_compact"] = args.answers

    workspace, workspace_root = build_workspace(root, resolved, extras, data)
    config_dir = workspace_root / "config"
    config_dir.mkdir(parents=True, exist_ok=True)
    with (config_dir / "workspace.json").open("w", encoding="utf-8") as f:
        json.dump(workspace, f, ensure_ascii=False, indent=2)

    project_config = root / "config"
    project_config.mkdir(parents=True, exist_ok=True)
    with (project_config / "workspace.json").open("w", encoding="utf-8") as f:
        json.dump(workspace, f, ensure_ascii=False, indent=2)

    print(
        json.dumps(
            {
                "resolved": resolved,
                "workspace_root": str(workspace_root),
                "workspace_written": str(config_dir / "workspace.json"),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
