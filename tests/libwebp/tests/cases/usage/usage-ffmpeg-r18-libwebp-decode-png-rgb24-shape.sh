#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r18-libwebp-decode-png-rgb24-shape
# @title: ffmpeg decodes a WEBP into a PNG and ffprobe reports the original dims
# @description: Encodes a generated PNG to WEBP via libwebp, then decodes the WEBP back to PNG with ffmpeg, and verifies ffprobe reports the original 80x60 dims on the PNG output to confirm the decode path through libwebp.
# @timeout: 180
# @tags: usage, ffmpeg, webp, decode, r18
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (80, 60))
for y in range(60):
    for x in range(80):
        img.putpixel((x, y), ((x * 7) & 0xff, (y * 11) & 0xff, ((x + y) * 3) & 0xff))
img.save(sys.argv[1])
PY

ffmpeg -hide_banner -y -i "$tmpdir/in.png" -vcodec libwebp -q:v 80 "$tmpdir/m.webp" >"$tmpdir/enc.log" 2>&1
file "$tmpdir/m.webp" | grep -q 'Web/P'

ffmpeg -hide_banner -y -i "$tmpdir/m.webp" "$tmpdir/out.png" >"$tmpdir/dec.log" 2>&1
file "$tmpdir/out.png" | grep -qi 'PNG image'

probe=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$tmpdir/out.png")
[[ "$probe" == "80,60" ]] || { printf 'unexpected dims: %s\n' "$probe" >&2; exit 1; }
