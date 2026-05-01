#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-rgba-png-anim
# @title: ffmpeg libwebp_anim from RGBA PNG sequence
# @description: Encodes three RGBA PNG frames with varying alpha into an animated WebP via ffmpeg's libwebp_anim and verifies Pillow reports n_frames>=3 with mode containing alpha after seek.
# @timeout: 240
# @tags: usage, webp, video, alpha
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys
out = Path(sys.argv[1])
colors = [(220, 30, 30, 255), (30, 220, 30, 180), (30, 30, 220, 96)]
for i, c in enumerate(colors):
    im = Image.new('RGBA', (8, 8), c)
    im.save(out / f"f{i:03d}.png", 'PNG')
PY

ffmpeg -hide_banner -loglevel error -y -framerate 5 \
  -i "$tmpdir/f%03d.png" \
  -c:v libwebp_anim -lossless 1 -loop 0 "$tmpdir/anim.webp"
validator_require_file "$tmpdir/anim.webp"

file "$tmpdir/anim.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

python3 - <<'PY' "$tmpdir/anim.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    assert im.format == 'WEBP', im.format
    assert im.size == (8, 8), im.size
    n = getattr(im, 'n_frames', 1)
    assert n >= 3, f"expected >=3 frames, got {n}"
    im.seek(0)
    rgba = im.convert('RGBA')
    assert rgba.mode == 'RGBA', rgba.mode
    print('rgba-anim-frames', n)
PY
