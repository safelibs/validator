#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
ORIGINAL_ROOT="$1"
STAGE="$2"
BASELINE="$ROOT/safe/abi/baseline/layouts.json"
PROBE="$ROOT/safe/tests/abi/layout_probe.c"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cc -DHAVE_CONFIG_H -I"$ORIGINAL_ROOT" -I"$ORIGINAL_ROOT/include" "$PROBE" -o "$TMPDIR/original-probe"
cc -I"$STAGE/usr/include/libxml2" "$PROBE" -o "$TMPDIR/stage-probe"

"$TMPDIR/original-probe" >"$TMPDIR/original.json"
"$TMPDIR/stage-probe" >"$TMPDIR/stage.json"

python3 - "$BASELINE" "$TMPDIR/original.json" "$TMPDIR/stage.json" <<'PY'
import json
import sys
from pathlib import Path

baseline = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
original = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
stage = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

if baseline != original:
    raise SystemExit("layout baseline does not match the current original header probe")
if baseline != stage:
    raise SystemExit("staged public headers drifted from the recorded layout baseline")
PY
