#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-append-images
# @title: Pillow WebP save_all with append_images list
# @description: Builds a four-frame animated WebP via Pillow with save_all and an explicit append_images list of three sibling frames, then reopens and asserts is_animated, n_frames==4, and that seek to each frame returns the expected solid color.
# @timeout: 180
# @tags: usage, webp, python, animation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-append-images"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmp = Path(sys.argv[2])

colors = [(255, 64, 64), (64, 255, 64), (64, 64, 255), (255, 255, 64)]
frames = [Image.new('RGB', (6, 6), c) for c in colors]

out = tmp / 'append.webp'
frames[0].save(
    out,
    'WEBP',
    save_all=True,
    append_images=frames[1:],
    duration=[50, 75, 100, 125],
    loop=0,
    lossless=True,
)

with Image.open(out) as im:
    assert im.format == 'WEBP', im.format
    assert getattr(im, 'is_animated', False)
    assert im.n_frames == 4, im.n_frames
    seen = []
    for idx in range(im.n_frames):
        im.seek(idx)
        seen.append(im.convert('RGB').getpixel((0, 0)))

assert seen == colors, f"frames mismatch: {seen}"
print('append_images frames', seen)
PY
