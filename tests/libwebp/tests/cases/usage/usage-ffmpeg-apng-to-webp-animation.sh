#!/usr/bin/env bash
# @testcase: usage-ffmpeg-apng-to-webp-animation
# @title: ffmpeg APNG to animated WebP
# @description: Builds an animated PNG via Pillow, transcodes it to animated WebP through ffmpeg's libwebp_anim encoder, and verifies the output is WebP with the expected dimensions.
# @timeout: 240
# @tags: usage, webp, video
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.apng"
from pathlib import Path
from PIL import Image
import sys
frames = [Image.new('RGBA', (8, 8), c) for c in (
    (255, 0, 0, 255), (0, 255, 0, 255), (0, 0, 255, 255),
)]
frames[0].save(
    sys.argv[1],
    format='PNG',
    save_all=True,
    append_images=frames[1:],
    duration=80,
    loop=0,
)
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.apng" \
  -c:v libwebp_anim -lossless 1 -loop 0 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"

file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

# Read it back through Pillow to confirm at least one frame decoded and the
# canvas matches the source dimensions.
python3 - <<'PY' "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    assert im.format == 'WEBP', im.format
    assert im.size == (8, 8), im.size
    n = getattr(im, 'n_frames', 1)
    assert n >= 1, n
    print('webp-frames', n)
PY
