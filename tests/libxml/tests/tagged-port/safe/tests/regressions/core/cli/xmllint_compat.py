#!/usr/bin/env python3
import os
import re
import subprocess
import sys
from pathlib import Path


def stage_libdir(stage: Path) -> Path:
    matches = sorted((stage / "usr/lib").glob("*"))
    if not matches:
        raise SystemExit(f"missing staged libxml2 library directory under {stage}")
    return matches[0]


def run_tool(binary: Path, libdir: Path, arg: str, cwd: Path) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = f"{libdir}:{env.get('LD_LIBRARY_PATH', '')}".rstrip(":")
    env.pop("XML_CATALOG_FILES", None)
    env.pop("SGML_CATALOG_FILES", None)
    return subprocess.run(
        [str(binary), arg],
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def normalize_binary_refs(text: str) -> str:
    text = text.replace("\r\n", "\n")
    text = re.sub(r"(?m)^(Usage : )\S*(?:/xmllint|xmllint)(\b)", r"\1xmllint\2", text)
    text = re.sub(r"(?m)^\S*(?:/xmllint|xmllint):", "xmllint:", text)
    return text


def stderr_lines(proc: subprocess.CompletedProcess[str]) -> list[str]:
    return [line.rstrip() for line in normalize_binary_refs(proc.stderr).splitlines()]


def main() -> int:
    root = Path(sys.argv[1])
    stage = Path(sys.argv[2])
    original = root / "original/.libs/xmllint"
    staged = stage / "usr/bin/xmllint"
    original_libdir = root / "original/.libs"
    staged_libdir = stage_libdir(stage)

    for path in (original, staged):
        if not path.is_file():
            raise SystemExit(f"missing xmllint binary for regression check: {path}")

    help_original = run_tool(original, original_libdir, "--help", root)
    help_staged = run_tool(staged, staged_libdir, "--help", root)

    if help_original.returncode != 1:
        raise SystemExit(f"original xmllint --help exit drifted to {help_original.returncode}")
    if help_staged.returncode != help_original.returncode:
        raise SystemExit(
            "staged xmllint --help exit mismatch:\n"
            f"original={help_original.returncode} staged={help_staged.returncode}\n"
            f"stderr:\n{help_staged.stderr}"
        )
    if help_staged.stdout:
        raise SystemExit(f"staged xmllint --help unexpectedly wrote stdout:\n{help_staged.stdout}")

    help_original_lines = stderr_lines(help_original)
    help_staged_lines = stderr_lines(help_staged)
    if help_original_lines[:3] != help_staged_lines[:3]:
        raise SystemExit(
            "staged xmllint --help banner drifted from original:\n"
            f"original:\n{help_original.stderr}\n"
            f"staged:\n{help_staged.stderr}"
        )

    version_original = run_tool(original, original_libdir, "--version", root)
    version_staged = run_tool(staged, staged_libdir, "--version", root)

    if version_original.returncode != 0:
        raise SystemExit(
            f"original xmllint --version exit drifted to {version_original.returncode}\n"
            f"stderr:\n{version_original.stderr}"
        )
    if version_staged.returncode != version_original.returncode:
        raise SystemExit(
            "staged xmllint --version exit mismatch:\n"
            f"original={version_original.returncode} staged={version_staged.returncode}\n"
            f"stderr:\n{version_staged.stderr}"
        )
    if version_staged.stdout:
        raise SystemExit(
            f"staged xmllint --version unexpectedly wrote stdout:\n{version_staged.stdout}"
        )

    version_original_lines = stderr_lines(version_original)
    version_staged_lines = stderr_lines(version_staged)
    if version_original_lines[:2] != version_staged_lines[:2]:
        raise SystemExit(
            "staged xmllint --version banner drifted from original:\n"
            f"original:\n{version_original.stderr}\n"
            f"staged:\n{version_staged.stderr}"
        )

    print("xmllint CLI regression checks passed: --help and --version match original semantics")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
