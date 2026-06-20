#!/usr/bin/env python3
"""Write auth failure logs and an empty failure report for a report date."""

from __future__ import annotations

import argparse
import sys
from datetime import datetime
from pathlib import Path

from workspace_lib import ensure_operation_log_layout, load_workspace, report_md_dir

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")


def append(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(text.rstrip() + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="生成授权失败空报告和操作日志")
    parser.add_argument("--date", required=True, help="YYYY-MM-DD")
    parser.add_argument("--platform", required=True, help="平台 ID 或名称")
    parser.add_argument("--error", required=True, help="错误摘要")
    parser.add_argument("--attempts", default="3", help="已尝试次数，默认 3")
    parser.add_argument("--project-root", default=None)
    args = parser.parse_args()

    root = (Path(args.project_root) if args.project_root else Path(__file__).resolve().parent.parent).resolve()
    ws = load_workspace(root)
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    log_dir = ensure_operation_log_layout(root, ws, args.date)
    msg = f"[{now}] AUTH_FAILED platform={args.platform} attempts={args.attempts} error={args.error}"
    append(log_dir / "auth-check.log", msg)
    append(log_dir / "errors.log", msg)
    append(log_dir / "run.log", f"[{now}] 正常日报已停止，已生成授权失败报告。")

    report_dir = report_md_dir(root, ws, args.date)
    report_dir.mkdir(parents=True, exist_ok=True)
    report_path = report_dir / "auth-failed.md"
    report_path.write_text(
        "\n".join(
            [
                f"# 营销日报生成失败（{args.date}）",
                "",
                "本次没有生成正常日报，因为平台授权检查失败。",
                "",
                "| 项目 | 内容 |",
                "|------|------|",
                f"| 失败平台 | {args.platform} |",
                f"| 尝试次数 | {args.attempts} |",
                f"| 错误摘要 | {args.error} |",
                f"| 记录时间 | {now} |",
                "",
                "## 下一步",
                "",
                "请在对应广告平台后台或当前 IDE 的 MCP/OAuth 面板重新授权。授权完成后，让 Agent 重新生成该日期的营销日报。",
                "",
                "## 日志位置",
                "",
                f"- `{log_dir / 'auth-check.log'}`",
                f"- `{log_dir / 'errors.log'}`",
                f"- `{log_dir / 'run.log'}`",
                "",
            ]
        ),
        encoding="utf-8",
    )

    print(f"已生成授权失败报告：{report_path}")
    print(f"已写入操作日志：{log_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
