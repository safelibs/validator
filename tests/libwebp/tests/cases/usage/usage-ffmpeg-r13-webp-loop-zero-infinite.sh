#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r13-webp-loop-zero-infinite
# @title: ffmpeg libwebp_anim -loop 0 produces a WEBP that Pillow reads as loop=0
# @description: Encodes a 3-frame APNG to animated WEBP via ffmpeg's libwebp_anim with -loop 0 and asserts Pillow reopens the result with im.info["loop"] == 0 (infinite), exercising the muxer loop-count round-trip.
# @timeout: 240
# @tags: usage, ffmpeg, webp, animation
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a 3-frame APNG via Pillow.
python3 - <<'PY' "$tmpdir/in.png"
import sys
from PIL import Image
frames = [Image.new('RGB', (24, 16), (40 + 50 * i, 80, 200 - 50 * i)) for i in range(3)]
frames[0].save(sys.argv[1], 'PNG', save_all=True, append_images=frames[1:],
               duration=80, loop=0)
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp_anim -loop 0 "$tmpdir/out.webp"
file "$tmpdir/out.webp" | grep -q 'Web/P'

python3 - <<'PY' "$tmpdir/out.webp"
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.info.get('loop') == 0, im.info.get('loop')
    assert im.n_frames >= 2, im.n_frames
PY
