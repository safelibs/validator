#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-seek-last-frame
# @title: Pillow WebP seek to last frame
# @description: Saves a four-frame animated WebP through Pillow then opens it and seeks directly to n_frames-1, verifying tell() and the pixel value at the last frame.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-seek-last-frame"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

colors = [(10, 20, 30), (60, 70, 80), (120, 130, 140), (200, 210, 220)]
frames = [Image.new('RGB', (4, 4), c) for c in colors]

out = tmpdir / 'anim4.webp'
frames[0].save(
    out,
    'WEBP',
    save_all=True,
    append_images=frames[1:],
    duration=50,
    loop=0,
    lossless=True,
)

with Image.open(out) as im:
    assert im.format == 'WEBP', im.format
    assert getattr(im, 'is_animated', False)
    assert im.n_frames == 4, im.n_frames
    last = im.n_frames - 1
    im.seek(last)
    assert im.tell() == last, im.tell()
    pixel = im.convert('RGB').getpixel((0, 0))

assert pixel == colors[-1], f"last-frame pixel mismatch: {pixel}"
print('last-frame', pixel)
PYCASE
