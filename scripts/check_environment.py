#!/usr/bin/env python3
"""检查本机是否具备运行营销 Agent 的基础环境。齐全则静默通过，缺失则输出安装指引。"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


MIN_PYTHON = (3, 10)


@dataclass
class EnvCheck:
    id: str
    name: str
    required: bool
    ok: bool
    detail: str
    install_hint: str


def _run_version(cmd: list[str]) -> str | None:
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if out.returncode != 0:
            return None
        return (out.stdout or out.stderr or "").strip().splitlines()[0] if (out.stdout or out.stderr) else None
    except (OSError, subprocess.TimeoutExpired):
        return None


def find_python() -> tuple[str | None, str | None]:
    candidates: list[list[str]] = []
    for name in ("python", "python3"):
        path = shutil.which(name)
        if path:
            candidates.append([path, "-c", "import sys; print('.'.join(map(str, sys.version_info[:3])))"])
    py_launcher = shutil.which("py")
    if py_launcher:
        candidates.append([py_launcher, "-3", "-c", "import sys; print('.'.join(map(str, sys.version_info[:3])))"])

    local_appdata = os.environ.get("LOCALAPPDATA")
    if local_appdata:
        for version in ("Python312", "Python311", "Python310"):
            path = Path(local_appdata) / "Programs" / "Python" / version / "python.exe"
            if path.exists():
                candidates.append([str(path), "-c", "import sys; print('.'.join(map(str, sys.version_info[:3])))"])

    for cmd in candidates:
        ver = _run_version(cmd)
        if ver:
            return cmd[0], ver
    return None, None


def version_tuple(text: str | None) -> tuple[int, ...]:
    if not text:
        return ()
    parts: list[int] = []
    for piece in text.split("."):
        if not piece.isdigit():
            break
        parts.append(int(piece))
    return tuple(parts)


def check_python() -> EnvCheck:
    path, ver = find_python()
    if not path:
        return EnvCheck(
            id="python",
            name="Python 3.10+",
            required=True,
            ok=False,
            detail="未检测到 Python",
            install_hint=(
                "Windows：打开 https://www.python.org/downloads/ 下载并安装 Python 3.12，"
                "安装时勾选「Add python.exe to PATH」。\n"
                "macOS：在终端运行 brew install python3\n"
                "安装后关闭并重新打开 Cursor，再运行配置向导。"
            ),
        )
    vt = version_tuple(ver)
    if vt < MIN_PYTHON:
        return EnvCheck(
            id="python",
            name="Python 3.10+",
            required=True,
            ok=False,
            detail=f"当前版本 {ver} 过低",
            install_hint="请安装 Python 3.10 或更高版本（推荐 3.12），并确保终端可执行 python 或 python3。",
        )
    return EnvCheck(
        id="python",
        name="Python 3.10+",
        required=True,
        ok=True,
        detail=f"{ver} ({path})",
        install_hint="",
    )


def check_pip() -> EnvCheck:
    py_path, _ = find_python()
    if not py_path:
        return EnvCheck(
            id="pip",
            name="pip（Python 包管理）",
            required=False,
            ok=False,
            detail="未检测（需先安装 Python）",
            install_hint="安装 Python 后通常自带 pip；若缺失可运行：python -m ensurepip --upgrade",
        )
    cmd = [py_path, "-m", "pip", "--version"] if py_path != "py" else ["py", "-3", "-m", "pip", "--version"]
    ver = _run_version(cmd)
    return EnvCheck(
        id="pip",
        name="pip（Python 包管理）",
        required=False,
        ok=bool(ver),
        detail=ver or "未检测到 pip",
        install_hint="运行：python -m ensurepip --upgrade",
    )


def check_python_docx() -> EnvCheck:
    py_path, _ = find_python()
    if not py_path:
        return EnvCheck(
            id="python_docx",
            name="python-docx（导出 Word）",
            required=False,
            ok=False,
            detail="未检测",
            install_hint="在项目目录运行：pip install -r requirements.txt",
        )
    cmd = [py_path, "-c", "import docx"] if py_path != "py" else ["py", "-3", "-c", "import docx"]
    try:
        subprocess.run(cmd, capture_output=True, timeout=15, check=True)
        return EnvCheck(
            id="python_docx",
            name="python-docx（导出 Word）",
            required=False,
            ok=True,
            detail="已安装",
            install_hint="",
        )
    except (subprocess.CalledProcessError, OSError, subprocess.TimeoutExpired):
        return EnvCheck(
            id="python_docx",
            name="python-docx（导出 Word）",
            required=False,
            ok=False,
            detail="未安装",
            install_hint="在项目目录运行：pip install -r requirements.txt（生成 Word 日报前需要）",
        )


def check_node() -> EnvCheck:
    path = shutil.which("node")
    ver = _run_version(["node", "-v"]) if path else None
    return EnvCheck(
        id="node",
        name="Node.js（部分广告平台 MCP）",
        required=False,
        ok=bool(ver),
        detail=ver or "未检测到",
        install_hint="Windows/macOS：打开 https://nodejs.org 安装 LTS 版本（连接 Meta/Adjust 等 MCP 时需要）",
    )


def check_pipx() -> EnvCheck:
    path = shutil.which("pipx")
    ver = _run_version(["pipx", "--version"]) if path else None
    return EnvCheck(
        id="pipx",
        name="pipx（Google Ads MCP）",
        required=False,
        ok=bool(ver),
        detail=ver or "未检测到",
        install_hint="运行：pip install pipx 然后 pipx ensurepath（连接 Google Ads MCP 时需要）",
    )


def run_checks(scope: str = "onboarding") -> list[EnvCheck]:
    checks = [check_python()]
    if scope in ("onboarding", "full"):
        checks.extend([check_pip(), check_python_docx(), check_node(), check_pipx()])
    return checks


def format_missing_message(checks: list[EnvCheck], *, required_only: bool = False) -> str:
    missing = [c for c in checks if not c.ok and (c.required or not required_only)]
    if not missing:
        return ""
    lines = ["本机还缺少运行营销 Agent 所需的环境，请先安装后再继续配置：", ""]
    for item in missing:
        tag = "【必需】" if item.required else "【建议稍后安装】"
        lines.append(f"{tag} {item.name}")
        lines.append(f"  状态：{item.detail}")
        if item.install_hint:
            lines.append(f"  怎么做：{item.install_hint}")
        lines.append("")
    lines.append("安装完成后，请重新运行：powershell -ExecutionPolicy Bypass -File scripts\\onboard.ps1")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="检查营销 Agent 运行环境")
    parser.add_argument("--scope", choices=["onboarding", "full"], default="onboarding")
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    parser.add_argument("--quiet", action="store_true", help="全部通过时不输出任何内容")
    args = parser.parse_args()

    checks = run_checks(args.scope)
    required_failed = [c for c in checks if c.required and not c.ok]
    ok = len(required_failed) == 0

    payload: dict[str, Any] = {
        "ok": ok,
        "checks": [asdict(c) for c in checks],
        "missing_required": [c.id for c in required_failed],
        "message": format_missing_message(checks, required_only=True) if not ok else "",
    }

    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    elif not ok:
        print(payload["message"])
    elif not args.quiet:
        print("环境检查通过（Python 已就绪）。")

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
