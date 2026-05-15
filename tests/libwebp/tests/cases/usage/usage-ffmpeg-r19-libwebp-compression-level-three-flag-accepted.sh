#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r19-libwebp-compression-level-three-flag-accepted
# @title: ffmpeg libwebp -compression_level 3 encodes a PNG to a non-empty WEBP
# @description: Drives ffmpeg's libwebp encoder with -compression_level 3 against a generated PNG input, asserts file(1) identifies the output as WEBP, and that ffprobe reports the original 72x54 dimensions on the encoded file.
# @timeout: 180
# @tags: usage, ffmpeg, webp, compression-level, r19
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (72, 54))
for y in range(54):
    for x in range(72):
        img.putpixel((x, y), ((x * 3) & 0xff, (y * 4) & 0xff, ((x ^ y) * 5) & 0xff))
img.save(sys.argv[1])
PY

ffmpeg -hide_banner -y -i "$tmpdir/in.png" -vcodec libwebp -compression_level 3 -q:v 72 "$tmpdir/out.webp" >"$tmpdir/ff.log" 2>&1
file "$tmpdir/out.webp" | grep -q 'Web/P'
test -s "$tmpdir/out.webp"

probe=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$tmpdir/out.webp")
[[ "$probe" == "72,54" ]] || { printf 'unexpected dims: %s\n' "$probe" >&2; exit 1; }
