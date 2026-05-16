#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r21-libwebp-preset-photo-flag-accepted
# @title: ffmpeg libwebp accepts -preset photo and produces a RIFF/WEBP file
# @description: Encodes a tiny rgb24 rawvideo source through ffmpeg's libwebp encoder with -preset photo, asserts the resulting file begins with RIFF....WEBP, pinning libwebp's photo preset propagation through the ffmpeg wrapper on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, ffmpeg, webp, preset, photo, r21
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/raw.rgb" <<'PY'
import sys
w, h = 24, 16
data = bytes(((x + y) & 0xff) for y in range(h) for x in range(w * 3))
with open(sys.argv[1], 'wb') as f:
    f.write(data)
PY

ffmpeg -loglevel error -hide_banner -y -f rawvideo -pix_fmt rgb24 -s 24x16 -i "$tmpdir/raw.rgb" \
    -frames:v 1 -vcodec libwebp -preset photo "$tmpdir/out.webp"

[[ -s "$tmpdir/out.webp" ]]
header=$(head -c 12 "$tmpdir/out.webp" | od -An -c | tr -d ' \n')
case "$header" in
    RIFF*WEBP*) : ;;
    *) echo "expected RIFF/WEBP header, got: $header" >&2; exit 1 ;;
esac
