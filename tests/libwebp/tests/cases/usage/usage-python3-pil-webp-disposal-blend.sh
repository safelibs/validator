#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-disposal-blend
# @title: Pillow WebP animated disposal/blend
# @description: Saves an animated WebP through Pillow with explicit disposal=2 and blend=0 per frame, then walks each frame back via seek and confirms pixel sampling.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-disposal-blend"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

colors = [(200, 30, 40), (30, 200, 40), (30, 40, 200)]
frames = [Image.new('RGB', (6, 6), c) for c in colors]

out = tmpdir / 'anim.webp'
# disposal=2 (background) and blend=0 (no blend) are the WebP-specific
# per-frame controls Pillow exposes for animated WebP saves.
frames[0].save(
    out,
    'WEBP',
    save_all=True,
    append_images=frames[1:],
    duration=60,
    loop=0,
    lossless=True,
    disposal=2,
    blend=0,
)

with Image.open(out) as im:
    assert im.format == 'WEBP', im.format
    assert getattr(im, 'is_animated', False)
    assert im.n_frames == 3, im.n_frames
    seen = []
    for idx in range(im.n_frames):
        im.seek(idx)
        seen.append(im.convert('RGB').getpixel((0, 0)))

assert seen == colors, f"frame colors mismatch: {seen}"
print('disposal-blend frames', seen)
PYCASE
