#!/usr/bin/env bash
# @testcase: usage-vips-r21-webpsave-q-50-vs-q-95-buffer-length-monotonic
# @title: vips webpsave_buffer at Q=50 yields a shorter buffer than Q=95 for identical source
# @description: Loads a JPEG via vips, encodes it to an in-memory WEBP buffer at Q=50 and Q=95 using webpsave_buffer, and asserts the Q=50 buffer length is strictly smaller than Q=95 — pinning vips' Q parameter propagation through libwebp's encoder on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, vips, webp, webpsave-buffer, quality, r21
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/src.jpg" <<'PY'
import sys, random
from PIL import Image
random.seed(7)
img = Image.new('RGB', (120, 90))
px = img.load()
for y in range(90):
    for x in range(120):
        px[x, y] = (random.randrange(256), random.randrange(256), random.randrange(256))
img.save(sys.argv[1], 'JPEG', quality=85)
PY

vips webpsave_buffer "$tmpdir/src.jpg" --Q 50 >"$tmpdir/q50.webp"
vips webpsave_buffer "$tmpdir/src.jpg" --Q 95 >"$tmpdir/q95.webp"

s_lo=$(stat -c '%s' "$tmpdir/q50.webp")
s_hi=$(stat -c '%s' "$tmpdir/q95.webp")
[[ "$s_lo" -lt "$s_hi" ]] || { printf 'expected Q=50 (%s) < Q=95 (%s)\n' "$s_lo" "$s_hi" >&2; exit 1; }
