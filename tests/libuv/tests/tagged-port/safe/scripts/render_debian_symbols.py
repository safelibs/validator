#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def load_dynamic_exports(path: Path) -> set[str]:
    contents = json.loads(path.read_text())
    return set(contents["linux_x86_64"]["dynamic_exports"])


def extract_symbol_name(line: str) -> str | None:
    match = re.search(r"([A-Za-z_][A-Za-z0-9_]*)@Base\b", line)
    if match is None:
        return None
    return match.group(1)


def render_symbols(exports: set[str], template_path: Path) -> list[str]:
    output: list[str] = []
    seen: set[str] = set()

    for raw_line in template_path.read_text().splitlines():
        if raw_line.startswith("libuv.so.1 "):
            output.append(raw_line)
            continue
        if raw_line.startswith("* Build-Depends-Package:"):
            output.append(raw_line)
            continue
        if raw_line.startswith("#"):
            continue

        symbol = extract_symbol_name(raw_line)
        if symbol is None:
            continue
        if symbol not in exports:
            continue

        output.append(raw_line)
        seen.add(symbol)

    missing = sorted(exports - seen)
    if missing:
        formatted = "\n".join(missing)
        raise SystemExit(
            "missing version mapping for exported symbols in template:\n"
            f"{formatted}"
        )

    return output


def main() -> int:
    if len(sys.argv) != 4:
        print(
            "usage: render_debian_symbols.py <abi-baseline.json> <template.symbols> <output.symbols>",
            file=sys.stderr,
        )
        return 64

    abi_path = Path(sys.argv[1])
    template_path = Path(sys.argv[2])
    output_path = Path(sys.argv[3])

    lines = render_symbols(load_dynamic_exports(abi_path), template_path)
    output_path.write_text("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
