#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r20-libwebp-encode-rgb24-source-produces-webp
# @title: ffmpeg libwebp encoder from an rgb24 rawvideo source emits a valid RIFF/WEBP container
# @description: Pipes a 32x24 rgb24 rawvideo frame into ffmpeg's libwebp encoder and asserts the produced file begins with the RIFF/WEBP signature (RIFF....WEBP), pinning the rawvideo->libwebp encode path on Ubuntu 24.04.
# @timeout: 180
# @tags: usage, ffmpeg, webp, rgb24, riff, r20
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/raw.rgb" <<'PY'
import sys
w, h = 32, 24
data = bytes(((x * 7 + y * 13) & 0xff) for y in range(h) for x in range(w * 3))
with open(sys.argv[1], 'wb') as f:
    f.write(data)
PY

ffmpeg -hide_banner -y -f rawvideo -pix_fmt rgb24 -s 32x24 -i "$tmpdir/raw.rgb" \
    -frames:v 1 -vcodec libwebp -q:v 70 "$tmpdir/out.webp" >"$tmpdir/ff.log" 2>&1

[[ -s "$tmpdir/out.webp" ]]
header=$(head -c 12 "$tmpdir/out.webp" | od -An -c | tr -d ' \n')
case "$header" in
    RIFF*WEBP*) : ;;
    *) echo "expected RIFF/WEBP header, got: $header" >&2; exit 1 ;;
esac
