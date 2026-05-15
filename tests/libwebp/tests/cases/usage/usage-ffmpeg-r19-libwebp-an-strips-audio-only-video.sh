#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r19-libwebp-an-strips-audio-only-video
# @title: ffmpeg libwebp encode with -an results in a WEBP carrying exactly one video stream
# @description: Encodes a PNG to WEBP via ffmpeg with -an explicitly disabling audio, then runs ffprobe to count streams in the output and asserts exactly one video stream and zero audio streams are present.
# @timeout: 180
# @tags: usage, ffmpeg, webp, streams, r19
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (64, 48))
for y in range(48):
    for x in range(64):
        img.putpixel((x, y), ((x * 4) & 0xff, (y * 5) & 0xff, ((x + y) * 6) & 0xff))
img.save(sys.argv[1])
PY

ffmpeg -hide_banner -y -i "$tmpdir/in.png" -vcodec libwebp -an -q:v 75 "$tmpdir/out.webp" >"$tmpdir/ff.log" 2>&1
file "$tmpdir/out.webp" | grep -q 'Web/P'

video_streams=$(ffprobe -v error -select_streams v -show_entries stream=index -of csv=p=0 "$tmpdir/out.webp" | wc -l)
audio_streams=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$tmpdir/out.webp" | wc -l)
[[ "$video_streams" == "1" ]] || { printf 'expected 1 video stream, got %s\n' "$video_streams" >&2; exit 1; }
[[ "$audio_streams" == "0" ]] || { printf 'expected 0 audio streams, got %s\n' "$audio_streams" >&2; exit 1; }
