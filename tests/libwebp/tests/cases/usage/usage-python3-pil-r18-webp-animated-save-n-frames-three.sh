#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-webp-animated-save-n-frames-three
# @title: Pillow WEBP save_all writes a 3-frame animation reporting n_frames=3 on reopen
# @description: Builds three distinct RGB frames in memory, saves them as an animated WEBP via Pillow with save_all=True and append_images, then reopens the file and asserts img.n_frames == 3 along with WEBP format identification.
# @timeout: 120
# @tags: usage, python3-pil, webp, animation, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/anim.webp" <<'PY'
import sys
from PIL import Image

frames = []
for f in range(3):
    img = Image.new('RGB', (40, 30), ((f * 80) & 0xff, 100, 200 - f * 50))
    frames.append(img)

frames[0].save(
    sys.argv[1], 'WEBP',
    save_all=True,
    append_images=frames[1:],
    duration=100,
    loop=0,
    quality=70,
)

with Image.open(sys.argv[1]) as out:
    out.load()
    assert out.format == 'WEBP', out.format
    assert out.n_frames == 3, out.n_frames
PY
