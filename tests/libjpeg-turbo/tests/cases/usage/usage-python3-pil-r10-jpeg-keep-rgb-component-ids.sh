#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-jpeg-keep-rgb-component-ids
# @title: Pillow JPEG keep_rgb encodes component IDs as R G B
# @description: Saves a JPEG with keep_rgb=True via Pillow and parses the SOF0 marker to confirm the three component IDs are 0x52, 0x47, 0x42 ('R', 'G', 'B') instead of the default 1, 2, 3 (YCbCr).
# @timeout: 180
# @tags: usage, jpeg, python, encoder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
out = base / "rgb.jpg"
src = Image.new("RGB", (32, 24))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x + y) * 3) & 255)
             for y in range(24) for x in range(32)])
src.save(out, "JPEG", quality=80, keep_rgb=True)

data = out.read_bytes()
# Find SOF0 (FFC0) marker.
i = data.find(b"\xff\xc0")
assert i > 0, "no SOF0 marker"
# SOF0 layout: FFC0 LL P Y Y X X Nf [Ci Hi/Vi Tqi]*Nf
nf = data[i + 9]
assert nf == 3, f"expected 3 components, got {nf}"
ids = [data[i + 10 + 3 * k] for k in range(3)]
assert ids == [0x52, 0x47, 0x42], f"component IDs: {ids}"
print("component-ids", ids)
PY
