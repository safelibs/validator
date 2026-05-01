#!/usr/bin/env bash
# @testcase: usage-ffmpeg-libwebp-anim-fps
# @title: ffmpeg libwebp_anim with explicit framerate
# @description: Encodes three PPM frames to animated WebP via ffmpeg's libwebp_anim with -framerate 4 and verifies the output decodes back through Pillow with three frames at the source size.
# @timeout: 240
# @tags: usage, webp, video
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
import sys
out = Path(sys.argv[1])
colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255)]
for i, c in enumerate(colors):
    pixels = bytes(c) * 64
    (out / f"f{i:03d}.ppm").write_bytes(b"P6\n8 8\n255\n" + pixels)
PY

ffmpeg -hide_banner -loglevel error -y -framerate 4 \
  -i "$tmpdir/f%03d.ppm" \
  -c:v libwebp_anim -loop 0 -q:v 80 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"

file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

python3 - <<'PY' "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    assert im.format == 'WEBP', im.format
    assert im.size == (8, 8), im.size
    n = getattr(im, 'n_frames', 1)
    assert n >= 3, f"expected >=3 frames, got {n}"
    print('anim-frames', n)
PY
