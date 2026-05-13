#!/usr/bin/env bash
# @testcase: usage-vips-r16-gravity-larger-canvas-correct-dims
# @title: vips gravity centre into 48x36 canvas yields the requested dimensions
# @description: Encodes a 24x18 PPM as JPEG then runs vips gravity centre 48 36 into a PNG output, asserting vipsheader reports the canvas dimensions 48x36 and the result is loadable by Pillow as a 48x36 image, exercising libjpeg-turbo decode followed by vips canvas placement.
# @timeout: 180
# @tags: usage, vips, jpeg, gravity
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 24, 18
pixels = bytes([128] * (W * H * 3))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + pixels)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips gravity "$tmpdir/in.jpg" "$tmpdir/out.png" centre 48 36

vipsheader "$tmpdir/out.png" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '48x36'

python3 - "$tmpdir/out.png" <<'PY'
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.size == (48, 36), im.size
PY
