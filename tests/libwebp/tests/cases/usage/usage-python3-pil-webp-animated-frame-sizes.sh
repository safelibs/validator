#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-animated-frame-sizes
# @title: Pillow animated WebP frame size verification
# @description: Encodes a four-frame animated WebP from Pillow and asserts that each decoded frame matches the canvas size and reports the expected solid color at the center pixel.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys
tmpdir = Path(sys.argv[1])
colors = [(255, 0, 0, 255), (0, 255, 0, 255), (0, 0, 255, 255), (255, 255, 0, 255)]
frames = [Image.new('RGBA', (12, 12), c) for c in colors]
out = tmpdir / 'anim.webp'
frames[0].save(out, 'WEBP', save_all=True, append_images=frames[1:],
               duration=120, loop=0, lossless=True)
with Image.open(out) as im:
    assert im.format == 'WEBP', im.format
    assert getattr(im, 'n_frames', 1) == 4
    for idx, expected in enumerate(colors):
        im.seek(idx)
        rgba = im.convert('RGBA')
        assert rgba.size == (12, 12), rgba.size
        center = rgba.getpixel((6, 6))
        assert center == expected, (idx, center, expected)
print('anim-frame-sizes', 4)
PY
