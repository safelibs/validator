#!/usr/bin/env bash
# @testcase: usage-vips-r21-colourspace-srgb-to-lab-format-float
# @title: vips colourspace srgb to lab on a JPEG produces a 3-band FLOAT image
# @description: Encodes an sRGB 40x32 RGB JPEG, runs vips colourspace target lab to convert to CIELAB, writes the result to a .v file, and asserts vipsheader reports bands=3 and format containing "FLOAT" - locking in libjpeg-turbo's RGB decode feeding vips's CIELAB colour-space conversion which outputs a floating-point representation.
# @timeout: 180
# @tags: usage, vips, colourspace, lab, jpeg, r21
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
W, H = 40, 32
im = Image.new("RGB", (W, H))
im.putdata([((x * 11) & 255, (y * 13) & 255, ((x + y) * 7) & 255)
             for y in range(H) for x in range(W)])
im.save(out, "JPEG", quality=90)
PY

vips colourspace "$tmpdir/in.jpg" "$tmpdir/lab.v" lab
bands=$(vipsheader -f bands "$tmpdir/lab.v")
fmt=$(vipsheader -f format "$tmpdir/lab.v")

[[ "$bands" == "3" ]] || { printf 'expected 3 bands, got %s\n' "$bands" >&2; exit 1; }
[[ "$fmt" == *FLOAT* ]] || { printf 'expected FLOAT format, got %s\n' "$fmt" >&2; exit 1; }
