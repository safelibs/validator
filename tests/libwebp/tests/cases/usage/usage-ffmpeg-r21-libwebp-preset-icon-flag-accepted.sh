#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r21-libwebp-preset-icon-flag-accepted
# @title: ffmpeg libwebp -preset icon emits a RIFF/WEBP file for a small rgb24 frame
# @description: Encodes a 16x16 rgb24 rawvideo frame through ffmpeg's libwebp encoder with -preset icon and asserts the output starts with RIFF/WEBP magic, pinning ffmpeg's icon preset routing through libwebp on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, ffmpeg, webp, preset, icon, r21
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/raw.rgb" <<'PY'
import sys
w, h = 16, 16
data = bytes((x * 17 + y * 11) & 0xff for y in range(h) for x in range(w * 3))
with open(sys.argv[1], 'wb') as f:
    f.write(data)
PY

ffmpeg -loglevel error -hide_banner -y -f rawvideo -pix_fmt rgb24 -s 16x16 -i "$tmpdir/raw.rgb" \
    -frames:v 1 -vcodec libwebp -preset icon "$tmpdir/out.webp"

[[ -s "$tmpdir/out.webp" ]]
header=$(head -c 12 "$tmpdir/out.webp" | od -An -c | tr -d ' \n')
case "$header" in
    RIFF*WEBP*) : ;;
    *) echo "expected RIFF/WEBP header, got: $header" >&2; exit 1 ;;
esac
