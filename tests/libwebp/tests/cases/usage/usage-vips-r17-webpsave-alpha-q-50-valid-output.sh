#!/usr/bin/env bash
# @testcase: usage-vips-r17-webpsave-alpha-q-50-valid-output
# @title: vips webpsave --alpha-q 50 produces a valid WEBP file from an RGBA PNG
# @description: Builds a tiny RGBA PNG via Pillow, encodes it to WEBP through vips webpsave with --alpha-q 50, and asserts the result is detected as WEBP by file(1) and that vipsheader reports dims matching the input PNG.
# @timeout: 120
# @tags: usage, vips, webp, alpha-q
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGBA', (48, 32), (10, 50, 100, 200))
for y in range(32):
    for x in range(48):
        img.putpixel((x, y), (x * 4 & 0xff, y * 7 & 0xff, (x + y) * 3 & 0xff, (x * y) & 0xff))
img.save(sys.argv[1])
PY

vips webpsave "$tmpdir/in.png" "$tmpdir/out.webp" --Q 80 --alpha-q 50
file "$tmpdir/out.webp" | grep -q 'Web/P'

w_out=$(vipsheader -f width "$tmpdir/out.webp")
h_out=$(vipsheader -f height "$tmpdir/out.webp")
[[ "$w_out" == "48" && "$h_out" == "32" ]] || {
    printf 'unexpected dims %sx%s\n' "$w_out" "$h_out" >&2
    exit 1
}
