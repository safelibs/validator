#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-pixbuf-from-file
# @title: gdk-pixbuf-thumbnailer WebP preserves square dims
# @description: Builds a 24x24 WebP fixture and asks gdk-pixbuf-thumbnailer for an 8-pixel thumbnail through the WebP pixbuf loader, verifying the output PNG exists, decodes via Pillow as a square 8x8 image, and that the thumbnailer fed pixels through the loader.
# @timeout: 180
# @tags: usage, webp, pixbuf, thumbnail
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
W, H = 24, 24
pixels = bytearray()
for y in range(H):
    for x in range(W):
        r = (x * 11) & 0xff
        g = (y * 13) & 0xff
        b = ((x + y) * 7) & 0xff
        pixels += bytes((r, g, b))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + bytes(pixels))
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
gdk-pixbuf-thumbnailer -s 8 "$tmpdir/in.webp" "$tmpdir/thumb.png"
validator_require_file "$tmpdir/thumb.png"
test "$(wc -c <"$tmpdir/thumb.png")" -gt 0

file "$tmpdir/thumb.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image'

python3 - <<'PY' "$tmpdir/thumb.png"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'PNG', im.format
    w, h = im.size
    # Source is square 24x24 so the longest side scales to 8.
    assert max(w, h) == 8, (w, h)
    assert w == 8 and h == 8, (w, h)
    print('thumb', im.size)
PY
