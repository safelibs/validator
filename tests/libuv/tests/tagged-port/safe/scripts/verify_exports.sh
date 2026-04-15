#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <candidate-libuv.so> <baseline-libuv.so> <debian-symbols>" >&2
  exit 64
fi

python3 - "$1" "$2" "$3" <<'PY'
import pathlib
import re
import subprocess
import sys

candidate, baseline, debian_symbols = sys.argv[1:4]

def read_exports(path: str) -> list[str]:
    output = subprocess.check_output(
        ["nm", "-D", "--defined-only", path],
        text=True,
    )
    symbols = []
    for line in output.splitlines():
        parts = line.split()
        if len(parts) < 3:
            continue
        symbols.append(parts[-1].split("@", 1)[0])
    return sorted(dict.fromkeys(symbols))

def read_required_debian_symbols(path: str) -> list[str]:
    required = []
    for raw_line in pathlib.Path(path).read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "optional" in line:
            continue
        match = re.search(r"([A-Za-z_][A-Za-z0-9_]*)@Base\b", line)
        if match:
            required.append(match.group(1))
    return sorted(dict.fromkeys(required))

candidate_exports = read_exports(candidate)
baseline_exports = read_exports(baseline)

if candidate_exports != baseline_exports:
    missing = sorted(set(baseline_exports) - set(candidate_exports))
    extra = sorted(set(candidate_exports) - set(baseline_exports))
    if missing:
        print("missing exports:", file=sys.stderr)
        for symbol in missing:
            print(symbol, file=sys.stderr)
    if extra:
        print("unexpected exports:", file=sys.stderr)
        for symbol in extra:
            print(symbol, file=sys.stderr)
    sys.exit(1)

required_symbols = read_required_debian_symbols(debian_symbols)
missing_required = sorted(set(required_symbols) - set(candidate_exports))
if missing_required:
    print("missing non-optional Debian symbols:", file=sys.stderr)
    for symbol in missing_required:
        print(symbol, file=sys.stderr)
    sys.exit(1)

print(
    f"verified {len(candidate_exports)} exports and {len(required_symbols)} non-optional Debian symbols"
)
PY
