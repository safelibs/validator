#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r16-webp-libwebp-anim-loop-five
# @title: ffmpeg libwebp_anim -loop 5 produces an animated WebP that Pillow reports with loop=5
# @description: Encodes a small synthetic two-frame PNG stream into an animated WebP via ffmpeg -c:v libwebp_anim -loop 5, re-opens the result with Pillow, and asserts is_animated is True and the info loop value is 5.
# @timeout: 180
# @tags: usage, ffmpeg, webp, animation, loop
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/frames"
python3 - "$tmpdir/frames" <<'PY'
import sys
from pathlib import Path
from PIL import Image
out = Path(sys.argv[1])
for i, color in enumerate([(220, 30, 30), (30, 220, 30), (30, 30, 220), (220, 220, 30)], start=1):
    Image.new('RGB', (32, 32), color).save(out / f'f{i:02d}.png', 'PNG')
PY

ffmpeg -loglevel error -y -framerate 5 -i "$tmpdir/frames/f%02d.png" \
    -c:v libwebp_anim -loop 5 "$tmpdir/anim.webp"
file "$tmpdir/anim.webp" | grep -q 'Web/P'

python3 - "$tmpdir/anim.webp" <<'PY'
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    assert getattr(im, 'is_animated', False), 'expected is_animated'
    assert im.info.get('loop') == 5, im.info.get('loop')
PY
