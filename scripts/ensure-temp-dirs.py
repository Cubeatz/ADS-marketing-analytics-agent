#!/usr/bin/env python3
"""Create temp and daily operation log directories from workspace config."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from workspace_lib import (
    cleanup_old_operation_logs,
    ensure_operation_log_layout,
    ensure_temp_layout,
    load_workspace,
)

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="创建 temp 分类目录和按天操作日志目录")
    parser.add_argument("--date", required=True, help="YYYY-MM-DD")
    parser.add_argument("--project-root", default=None)
    args = parser.parse_args()

    root = (Path(args.project_root) if args.project_root else Path(__file__).resolve().parent.parent).resolve()
    ws = load_workspace(root)

    dirs = ensure_temp_layout(root, ws, args.date)
    log_dir = ensure_operation_log_layout(root, ws, args.date)
    removed_logs = cleanup_old_operation_logs(root, ws)

    print(f"已创建/确认 {len(dirs)} 个 temp 子目录（日期 {args.date}）")
    for d in sorted(set(str(p.relative_to(root)) for p in dirs))[:20]:
        print(f"  {d}")
    if len(dirs) > 20:
        print(f"  ... 共 {len(dirs)} 个")
    print(f"已创建/确认操作日志目录：{log_dir.relative_to(root)}")
    if removed_logs:
        print(f"已清理 {len(removed_logs)} 个超过保留期的旧日志目录")
    return 0


if __name__ == "__main__":
    sys.exit(main())
