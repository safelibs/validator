#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-paste-corner
# @title: Pillow WebP paste corner
# @description: Pastes a WebP fixture into the right half of a black canvas with Pillow and verifies the unpasted left corner stays black after a WebP round trip.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-paste-corner"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_ppm() {
  python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY
}

make_webp() {
  make_ppm
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

make_webp
python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    rgb = im.convert("RGB")
    canvas = Image.new("RGB", (rgb.size[0] * 2, rgb.size[1]), (0, 0, 0))
    canvas.paste(rgb, (rgb.size[0], 0))
    canvas.save(sys.argv[2], "WEBP", lossless=True)
with Image.open(sys.argv[2]) as out:
    out.load()
    assert out.size == (rgb.size[0] * 2, rgb.size[1])
    assert out.getpixel((0, 0)) == (0, 0, 0)
    print("paste", out.size)
PY
