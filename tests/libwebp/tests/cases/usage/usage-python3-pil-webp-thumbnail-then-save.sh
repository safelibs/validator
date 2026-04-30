#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-thumbnail-then-save
# @title: Pillow WebP thumbnail then save
# @description: Opens a WebP fixture with Pillow, calls Image.thumbnail to shrink in place, saves the result as a new WebP, and reloads it to verify it is valid WEBP with shrunk dimensions.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-thumbnail-then-save"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_webp() {
  python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
w, h = 16, 12
pixels = bytearray()
for y in range(h):
    for x in range(w):
        pixels += bytes([(x * 11) % 256, (y * 23) % 256, ((x + y) * 7) % 256])
Path(sys.argv[1]).write_bytes(b"P6\n%d %d\n255\n" % (w, h) + bytes(pixels))
PY
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

make_webp
python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/thumb.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    assert im.format == 'WEBP'
    im.thumbnail((4, 4))
    assert im.size[0] <= 4 and im.size[1] <= 4
    im.save(sys.argv[2], 'WEBP')
with Image.open(sys.argv[2]) as out:
    out.load()
    assert out.format == 'WEBP', out.format
    assert out.size[0] <= 4 and out.size[1] <= 4, out.size
    print('thumbnail-then-save', out.size)
PY

file "$tmpdir/thumb.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'
