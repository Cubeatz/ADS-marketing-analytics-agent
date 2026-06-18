"""工作区配置：路径解析、temp 分层目录、投递模式。"""

from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any


def load_workspace(project_root: Path) -> dict[str, Any]:
    for name in ("workspace.json", "workspace.example.json"):
        path = project_root / "config" / name
        if path.exists():
            with path.open(encoding="utf-8") as f:
                return json.load(f)
    return {}


def default_workspace_root() -> Path:
    """桌面 marketing-analytics-agent 默认路径（兼容中文「桌面」）。"""
    home = Path.home()
    for desktop in (home / "Desktop", home / "桌面"):
        if desktop.is_dir():
            return (desktop / "marketing-analytics-agent").resolve()
    return (home / "marketing-analytics-agent").resolve()


def workspace_data_root(project_root: Path, workspace: dict[str, Any]) -> Path:
    """报告与 temp 的实际根目录。"""
    dirs = workspace.get("directories") or {}
    raw = (dirs.get("workspace_root") or "").strip()
    if raw:
        return Path(raw).expanduser().resolve()
    return project_root.resolve()


def detect_prior_usage(root: Path) -> dict[str, Any]:
    """检测文件夹是否已有 Agent 使用记录。"""
    markers: list[str] = []
    root = root.expanduser().resolve()
    ws_path = root / "config" / "workspace.json"
    if ws_path.exists():
        try:
            ws = json.load(ws_path.open(encoding="utf-8"))
            ob = ws.get("onboarding") or {}
            if ob.get("completed"):
                markers.append("已完成首次配置")
            if ob.get("completed_at"):
                markers.append(f"上次配置时间：{ob['completed_at']}")
            platforms = [k for k, v in (ws.get("platforms") or {}).items() if v.get("enabled")]
            if platforms:
                markers.append(f"已启用平台：{', '.join(platforms)}")
        except (json.JSONDecodeError, OSError):
            markers.append("存在 config/workspace.json（可能不完整）")
    for name in ("temp", "reports", "output"):
        p = root / name
        if p.is_dir():
            try:
                if any(p.iterdir()):
                    markers.append(f"已有 {name}/ 数据")
            except OSError:
                pass
    return {
        "path": str(root),
        "has_prior": len(markers) > 0,
        "markers": markers,
    }


def initialize_workspace_root(
    workspace_root: Path,
    template_root: Path | None = None,
) -> Path:
    """创建桌面工作区骨架：config、temp、reports、output 及示例配置。"""
    workspace_root = workspace_root.expanduser().resolve()
    workspace_root.mkdir(parents=True, exist_ok=True)
    for sub in ("config", "reports", "output/documents"):
        (workspace_root / sub).mkdir(parents=True, exist_ok=True)

    template_root = template_root or Path(__file__).resolve().parent.parent
    config_dir = workspace_root / "config"
    for example in ("thresholds.example.json", "accounts.example.json", "feishu.example.json"):
        src = template_root / "config" / example
        dst_name = example.replace(".example", "")
        dst = config_dir / dst_name
        if src.exists() and not dst.exists():
            shutil.copy2(src, dst)

    # temp 顶层分类目录占位
    for cat in ("raw", "processed", "cache", "logs", "exports"):
        (workspace_root / "temp" / cat).mkdir(parents=True, exist_ok=True)

    return workspace_root


def resolve_path(project_root: Path, workspace: dict[str, Any], rel: str) -> Path:
    """相对路径基于 workspace_data_root。"""
    root = workspace_data_root(project_root, workspace)
    return root / rel
def is_onboarding_complete(workspace: dict[str, Any]) -> bool:
    return bool((workspace.get("onboarding") or {}).get("completed"))


def _expand(path_template: str, date: str | None = None, platform: str | None = None, category: str | None = None) -> str:
    out = path_template
    if date:
        out = out.replace("{date}", date)
    if platform:
        out = out.replace("{platform}", platform)
    if category:
        out = out.replace("{category}", category)
    return out


def temp_config(workspace: dict[str, Any]) -> dict[str, Any]:
    dirs = workspace.get("directories") or {}
    return dirs.get("temp") or {}


def enabled_platforms(workspace: dict[str, Any]) -> list[str]:
    platforms = workspace.get("platforms") or {}
    enabled = [k for k, v in platforms.items() if v.get("enabled")]
    if enabled:
        return enabled
    return temp_config(workspace).get("platforms") or [
        "google_ads", "meta_ads", "adjust", "appsflyer",
        "linkedin_ads", "bing_ads", "reddit_ads",
    ]


def categories_for_platform(workspace: dict[str, Any], platform: str) -> list[str]:
    cfg = temp_config(workspace)
    by_platform = cfg.get("categories_by_platform") or {}
    return by_platform.get(platform) or ["misc"]


def temp_category_path(
    project_root: Path,
    workspace: dict[str, Any],
    category: str,
    date: str,
    platform: str | None = None,
    subcategory: str | None = None,
) -> Path:
    """category: raw | processed | cache | logs | exports"""
    data_root = workspace_data_root(project_root, workspace)
    cfg = temp_config(workspace)
    categories = cfg.get("categories") or {}
    cat_cfg = categories.get(category)
    if not cat_cfg:
        # 兼容旧配置
        if category == "raw":
            base = data_root / "temp" / "raw" / date
            if platform:
                base = base / platform
            if subcategory:
                base = base / subcategory
            return base
        raise KeyError(f"Unknown temp category: {category}")

    path_tpl = cat_cfg.get("path") or f"temp/{category}/{{date}}/{{platform}}/{{category}}"
    plat = platform or "_shared"
    sub = subcategory or "_root"

    if "{category}" in path_tpl:
        rel = _expand(path_tpl, date=date, platform=plat, category=sub)
    elif "{platform}" in path_tpl:
        rel = _expand(path_tpl, date=date, platform=plat)
        if subcategory and sub != "_root":
            rel = f"{rel}/{subcategory}"
    else:
        rel = _expand(path_tpl, date=date)

    return data_root / rel


def temp_raw_path(
    project_root: Path,
    workspace: dict[str, Any],
    date: str,
    platform: str,
    data_category: str,
) -> Path:
    return temp_category_path(project_root, workspace, "raw", date, platform, data_category)


def temp_processed_path(
    project_root: Path,
    workspace: dict[str, Any],
    date: str,
    platform: str,
    data_category: str,
) -> Path:
    return temp_category_path(project_root, workspace, "processed", date, platform, data_category)


def temp_cache_path(
    project_root: Path,
    workspace: dict[str, Any],
    date: str,
    platform: str,
) -> Path:
    return temp_category_path(project_root, workspace, "cache", date, platform)


def temp_logs_path(project_root: Path, workspace: dict[str, Any], date: str) -> Path:
    return temp_category_path(project_root, workspace, "logs", date)


def temp_exports_path(
    project_root: Path,
    workspace: dict[str, Any],
    date: str,
    platform: str,
    data_category: str,
) -> Path:
    return temp_category_path(project_root, workspace, "exports", date, platform, data_category)


def ensure_temp_layout(project_root: Path, workspace: dict[str, Any], date: str) -> list[Path]:
    """创建当日 temp 全部分类子目录，返回创建的目录列表。"""
    data_root = workspace_data_root(project_root, workspace)
    created: list[Path] = []
    cfg = temp_config(workspace)
    if not cfg:
        # 最小兼容
        for p in ["raw", "processed", "cache", "logs", "exports"]:
            for plat in enabled_platforms(workspace):
                d = data_root / "temp" / p / date / plat
                d.mkdir(parents=True, exist_ok=True)
                created.append(d)
        return created

    for plat in enabled_platforms(workspace):
        for cat in categories_for_platform(workspace, plat):
            for kind in ("raw", "processed", "exports"):
                if kind in (cfg.get("categories") or {}):
                    p = temp_category_path(project_root, workspace, kind, date, plat, cat)
                    p.mkdir(parents=True, exist_ok=True)
                    created.append(p)
            cp = temp_cache_path(project_root, workspace, date, plat)
            cp.mkdir(parents=True, exist_ok=True)
            created.append(cp)

    shared = (cfg.get("shared_categories") or {}).get("processed") or ["blended"]
    for sc in shared:
        p = temp_category_path(project_root, workspace, "processed", date, sc, "_root")
        p.mkdir(parents=True, exist_ok=True)
        created.append(p)

    lp = temp_logs_path(project_root, workspace, date)
    lp.mkdir(parents=True, exist_ok=True)
    created.append(lp)

    return created


def report_md_dir(project_root: Path, workspace: dict[str, Any], date: str) -> Path:
    dirs = workspace.get("directories") or {}
    rel = dirs.get("reports_md") or "reports"
    return workspace_data_root(project_root, workspace) / rel / date


def document_dir(project_root: Path, workspace: dict[str, Any], date: str) -> Path:
    dirs = workspace.get("directories") or {}
    rel = dirs.get("documents") or "output/documents"
    return workspace_data_root(project_root, workspace) / rel / date


def delivery_mode(workspace: dict[str, Any]) -> str:
    return (workspace.get("delivery") or {}).get("mode") or "local_docx"


def feishu_webhook_config(workspace: dict[str, Any]) -> dict[str, Any]:
    return (workspace.get("feishu") or {}).get("webhook") or {}


def feishu_webhook_configured(workspace: dict[str, Any]) -> bool:
    wh = feishu_webhook_config(workspace)
    if not wh.get("enabled"):
        return False
    url = (wh.get("url") or "").strip()
    if not url:
        return False
    bad = ("YOUR_WEBHOOK", "placeholder", "example.com")
    return not any(b.lower() in url.lower() for b in bad)


def sync_legacy_feishu_json(project_root: Path, workspace: dict[str, Any]) -> None:
    data_root = workspace_data_root(project_root, workspace)
    feishu_path = data_root / "config" / "feishu.json"
    feishu_path.parent.mkdir(parents=True, exist_ok=True)
    wh = feishu_webhook_config(workspace)
    delivery = workspace.get("delivery") or {}
    dirs = workspace.get("directories") or {}
    doc_rel = dirs.get("documents", "output/documents")
    payload = {
        "enabled": bool(wh.get("enabled")),
        "webhook_url": wh.get("url") or "",
        "mention_all": bool(wh.get("mention_all", False)),
        "report_title_prefix": delivery.get("report_title_prefix", "【营销日报】"),
        "docx_fallback": {
            "enabled": True,
            "output_dir": f"{doc_rel}/{{date}}",
            "filename": delivery.get("local_docx_filename", "daily-report.docx"),
            "custom_output_dir": "",
        },
    }
    with feishu_path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


# 兼容旧名
def raw_platform_dir(project_root: Path, workspace: dict[str, Any], date: str, platform: str) -> Path:
    return temp_raw_path(project_root, workspace, date, platform, "misc")
