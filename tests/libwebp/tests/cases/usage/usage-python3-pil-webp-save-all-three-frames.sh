#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-save-all-three-frames
# @title: Pillow WebP save_all three frames
# @description: Writes a three-frame animated WebP via Pillow save_all and walks each frame back with seek.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-save-all-three-frames"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255)]
frames = [Image.new('RGB', (4, 4), c) for c in colors]

out = tmpdir / 'anim3.webp'
frames[0].save(
    out,
    'WEBP',
    save_all=True,
    append_images=frames[1:],
    duration=[40, 60, 80],
    loop=0,
    lossless=True,
)

with Image.open(out) as im:
    assert im.format == 'WEBP'
    assert getattr(im, 'is_animated', False)
    assert im.n_frames == 3
    seen = []
    for idx in range(im.n_frames):
        im.seek(idx)
        rgb = im.convert('RGB')
        seen.append(rgb.getpixel((0, 0)))

assert seen == colors, f"frame colors mismatch: {seen}"
print('frames', seen)
PYCASE
