#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-loop-three
# @title: ffmpeg libwebp_anim explicit loop count
# @description: Encodes a multi-frame animated WebP through ffmpeg libwebp_anim with -loop 3 and verifies Pillow reads back the loop count from im.info.
# @timeout: 240
# @tags: usage, webp, video, loop
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
import sys
out = Path(sys.argv[1])
colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]
for i, c in enumerate(colors):
    pixels = bytes(c) * 64
    (out / f"f{i:03d}.ppm").write_bytes(b"P6\n8 8\n255\n" + pixels)
PY

ffmpeg -hide_banner -loglevel error -y -framerate 4 \
  -i "$tmpdir/f%03d.ppm" \
  -c:v libwebp_anim -loop 3 -q:v 75 "$tmpdir/anim.webp"
validator_require_file "$tmpdir/anim.webp"

file "$tmpdir/anim.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

python3 - <<'PY' "$tmpdir/anim.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    assert im.format == 'WEBP', im.format
    assert getattr(im, 'is_animated', False)
    n = im.n_frames
    assert n >= 4, f"expected >=4 frames, got {n}"
    loop = im.info.get('loop')
    assert loop == 3, f"expected loop=3, got {loop!r}"
    print('loop', loop, 'n_frames', n)
PY
