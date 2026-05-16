#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r21-libwebp-quality-monotonic-q5-q95
# @title: ffmpeg libwebp encoder produces strictly smaller output at q=5 than q=95 from identical rawvideo
# @description: Encodes the same 64x48 rgb24 rawvideo frame twice via ffmpeg's libwebp encoder at -quality 5 and -quality 95, asserting the q=5 output is strictly smaller than the q=95 output — pinning ffmpeg's libwebp -quality knob to libwebp's quality/size curve on Ubuntu 24.04.
# @timeout: 180
# @tags: usage, ffmpeg, webp, quality, monotonic, r21
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/raw.rgb" <<'PY'
import sys, os, random
random.seed(1234)
w, h = 64, 48
data = bytes(random.randrange(256) for _ in range(w * h * 3))
with open(sys.argv[1], 'wb') as f:
    f.write(data)
PY

ffmpeg -loglevel error -hide_banner -y -f rawvideo -pix_fmt rgb24 -s 64x48 -i "$tmpdir/raw.rgb" \
    -frames:v 1 -vcodec libwebp -quality 5 "$tmpdir/q05.webp"
ffmpeg -loglevel error -hide_banner -y -f rawvideo -pix_fmt rgb24 -s 64x48 -i "$tmpdir/raw.rgb" \
    -frames:v 1 -vcodec libwebp -quality 95 "$tmpdir/q95.webp"

s_low=$(stat -c '%s' "$tmpdir/q05.webp")
s_high=$(stat -c '%s' "$tmpdir/q95.webp")
[[ "$s_low" -lt "$s_high" ]] || { printf 'expected q=5 (%s) < q=95 (%s)\n' "$s_low" "$s_high" >&2; exit 1; }
