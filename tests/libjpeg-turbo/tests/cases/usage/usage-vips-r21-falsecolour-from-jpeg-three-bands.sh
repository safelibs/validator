#!/usr/bin/env bash
# @testcase: usage-vips-r21-falsecolour-from-jpeg-three-bands
# @title: vips falsecolour from a single-band JPEG emits a 3-band JPEG result
# @description: Encodes a grayscale 48x32 JPEG via Pillow's L-mode, decodes/transforms it through vips falsecolour, encodes the result back to JPEG, and asserts the produced file has exactly 3 bands - locking in libjpeg-turbo's grayscale decode path feeding vips's false-colour LUT expansion to RGB.
# @timeout: 180
# @tags: usage, vips, falsecolour, jpeg, r21
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
out = base / "gray.jpg"
W, H = 48, 32
im = Image.new("L", (W, H))
im.putdata([(x * 5 + y * 7) & 255 for y in range(H) for x in range(W)])
im.save(out, "JPEG", quality=90)
PY

vips falsecolour "$tmpdir/gray.jpg" "$tmpdir/fc.jpg"
bands=$(vipsheader -f bands "$tmpdir/fc.jpg")
[[ "$bands" == "3" ]] || { printf 'expected 3 bands after falsecolour, got %s\n' "$bands" >&2; exit 1; }
