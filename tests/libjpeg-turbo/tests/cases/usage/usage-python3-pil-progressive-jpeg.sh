#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys

pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

cjpeg -progressive "$tmpdir/in.ppm" >"$tmpdir/progressive.jpg"
python3 - <<'PY' "$tmpdir/progressive.jpg"
from PIL import Image
import sys

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.size == (4, 3), im.size
    assert im.mode == "RGB", im.mode
    assert im.info.get("progressive") == 1 or im.info.get("progression") == 1, im.info
    print("progressive", im.size, im.mode)
PY
