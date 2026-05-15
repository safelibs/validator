#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r20-libwebp-show-frames-pkt-size-positive
# @title: ffprobe -show_frames on a libwebp-encoded still reports a positive pkt_size for the frame
# @description: Encodes a PNG to WEBP via ffmpeg's libwebp encoder, then runs ffprobe -show_frames -of csv on the v:0 stream and asserts the captured pkt_size column is an integer greater than zero, confirming the libwebp-produced frame has a non-empty packet payload.
# @timeout: 180
# @tags: usage, ffmpeg, webp, show-frames, pkt-size, r20
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (48, 36), (200, 80, 30))
img.save(sys.argv[1])
PY

ffmpeg -hide_banner -y -i "$tmpdir/in.png" -vcodec libwebp -q:v 75 "$tmpdir/out.webp" >"$tmpdir/ff.log" 2>&1

ffprobe -v error -select_streams v:0 -show_entries frame=pkt_size \
    -of csv=p=0 "$tmpdir/out.webp" >"$tmpdir/frames.csv"

first_size=$(head -n 1 "$tmpdir/frames.csv" | tr -d '\r')
[[ -n "$first_size" ]] || { echo "no frame size in ffprobe output" >&2; cat "$tmpdir/frames.csv" >&2; exit 1; }
[[ "$first_size" =~ ^[0-9]+$ ]] || { echo "pkt_size not integer: $first_size" >&2; exit 1; }
(( first_size > 0 )) || { echo "pkt_size not positive: $first_size" >&2; exit 1; }
