#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGE="$1"
ORIGINAL_DSO="$2"
BASELINE="$ROOT/safe/abi/baseline/exports.txt"

extract_exports() {
  objdump -T "$1" | python3 -c '
import re
import sys

pattern = re.compile(r"^\S+\s+g\s+\S+\s+\S+\s+\S+\s+(\S+)\s+([A-Za-z_][A-Za-z0-9_]*)$")
for raw_line in sys.stdin:
    match = pattern.match(raw_line.strip())
    if not match:
        continue
    version, name = match.groups()
    if name.startswith("LIBXML2_") or name == "Base":
        continue
    print(f"{name}@{version}")
'
}

STAGE_DSO="$(find "$STAGE" -path '*/libxml2.so.2.9.14' -print -quit)"
if [[ -z "$STAGE_DSO" ]]; then
  printf 'missing staged libxml2.so.2.9.14 under %s\n' "$STAGE" >&2
  exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

extract_exports "$ORIGINAL_DSO" | sort >"$TMPDIR/original.txt"
extract_exports "$STAGE_DSO" | sort >"$TMPDIR/stage.txt"
sort "$BASELINE" >"$TMPDIR/baseline.txt"

diff -u "$TMPDIR/baseline.txt" "$TMPDIR/original.txt"
diff -u "$TMPDIR/baseline.txt" "$TMPDIR/stage.txt"
