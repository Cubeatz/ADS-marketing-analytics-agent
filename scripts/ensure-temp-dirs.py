#!/usr/bin/env python3
"""按 workspace 配置创建 temp 分层目录骨架。"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from workspace_lib import ensure_temp_layout, is_onboarding_complete, load_workspace

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="创建 temp 分类子目录")
    parser.add_argument("--date", required=True, help="YYYY-MM-DD")
    parser.add_argument("--project-root", default=None)
    args = parser.parse_args()

    root = Path(args.project_root) if args.project_root else Path(__file__).resolve().parent.parent
    ws = load_workspace(root)

    dirs = ensure_temp_layout(root, ws, args.date)
    print(f"已创建/确认 {len(dirs)} 个 temp 子目录（日期 {args.date}）")
    for d in sorted(set(str(p.relative_to(root)) for p in dirs))[:20]:
        print(f"  {d}")
    if len(dirs) > 20:
        print(f"  ... 共 {len(dirs)} 个")
    return 0


if __name__ == "__main__":
    sys.exit(main())
