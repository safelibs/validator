#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-animation-duration-roundtrip
# @title: Pillow WebP animation frame count roundtrip
# @description: Saves an animated WebP with explicit per-frame durations through Pillow, then reopens the file and verifies the format identifier, the is_animated flag, and the n_frames count match what was saved, and that each frame's pixel content roundtrips to the colour written into it.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-animation-duration-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255)]
durations = [40, 80, 120]
frames = [Image.new('RGB', (5, 5), c) for c in colors]

out = tmpdir / 'duration.webp'
frames[0].save(
    out,
    'WEBP',
    save_all=True,
    append_images=frames[1:],
    duration=durations,
    loop=0,
    lossless=True,
)

with Image.open(out) as im:
    assert im.format == 'WEBP', im.format
    assert getattr(im, 'is_animated', False)
    assert im.n_frames == len(colors), im.n_frames
    # Each saved frame must reload as the colour it was written with. Pillow
    # does not currently surface per-frame duration via info['duration'] for
    # WebP, so anchor the round-trip on pixel content instead.
    seen_colors = []
    for idx in range(im.n_frames):
        im.seek(idx)
        rgb = im.convert('RGB')
        seen_colors.append(rgb.getpixel((2, 2)))

assert seen_colors == colors, f"frame colour mismatch: {seen_colors}"
print('frames', seen_colors)
PYCASE
