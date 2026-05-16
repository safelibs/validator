#!/usr/bin/env bash
# @testcase: usage-vips-r21-vipsthumbnail-explicit-dimensions
# @title: vipsthumbnail -s 32x32 on a 96x64 JPEG fits within the 32x32 bounding box
# @description: Encodes a 96x64 RGB JPEG via Pillow, runs vipsthumbnail -s 32x32 -o output, then asserts vipsheader reports the resulting JPEG's width is exactly 32 and the height is no more than 32 - locking in vipsthumbnail's WIDTHxHEIGHT bounding-box semantics (existing tests covered scalar size and a different -s ratio).
# @timeout: 180
# @tags: usage, vips, vipsthumbnail, jpeg, dimensions, r21
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
out = base / "in.jpg"
W, H = 96, 64
im = Image.new("RGB", (W, H))
im.putdata([((x * 13) & 255, (y * 7) & 255, ((x ^ y) * 5) & 255)
             for y in range(H) for x in range(W)])
im.save(out, "JPEG", quality=90)
PY

vipsthumbnail -s 32x32 -o "$tmpdir/thumb.jpg" "$tmpdir/in.jpg"
w=$(vipsheader -f width "$tmpdir/thumb.jpg")
h=$(vipsheader -f height "$tmpdir/thumb.jpg")

[[ "$w" == "32" ]] || { printf 'expected width 32, got %s\n' "$w" >&2; exit 1; }
[[ "$h" -le 32 && "$h" -ge 1 ]] || { printf 'expected 1 <= height <= 32, got %s\n' "$h" >&2; exit 1; }
