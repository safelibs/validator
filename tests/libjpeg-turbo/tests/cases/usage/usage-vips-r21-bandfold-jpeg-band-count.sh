#!/usr/bin/env bash
# @testcase: usage-vips-r21-bandfold-jpeg-band-count
# @title: vips bandfold on an RGB JPEG folds the width into the band axis
# @description: Encodes a 32x16 RGB JPEG, decodes/transforms it through vips bandfold, writes the result to a .v file, and asserts vipsheader reports the bands count equals 32*3 = 96 and the width equals 1 - locking in libjpeg-turbo's RGB decode followed by vips's bandfold reshape that converts horizontal pixels into additional bands.
# @timeout: 180
# @tags: usage, vips, bandfold, jpeg, r21
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
W, H = 32, 16
im = Image.new("RGB", (W, H))
im.putdata([((x * 9) & 255, (y * 5) & 255, ((x + y) * 3) & 255)
             for y in range(H) for x in range(W)])
im.save(out, "JPEG", quality=90)
PY

vips bandfold "$tmpdir/in.jpg" "$tmpdir/bf.v"
w=$(vipsheader -f width "$tmpdir/bf.v")
h=$(vipsheader -f height "$tmpdir/bf.v")
bands=$(vipsheader -f bands "$tmpdir/bf.v")

[[ "$w" == "1" ]] || { printf 'expected width 1, got %s\n' "$w" >&2; exit 1; }
[[ "$h" == "16" ]] || { printf 'expected height 16, got %s\n' "$h" >&2; exit 1; }
[[ "$bands" == "96" ]] || { printf 'expected 96 bands, got %s\n' "$bands" >&2; exit 1; }
