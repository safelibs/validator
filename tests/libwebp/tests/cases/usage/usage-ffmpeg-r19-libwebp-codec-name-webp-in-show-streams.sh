#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r19-libwebp-codec-name-webp-in-show-streams
# @title: ffprobe -show_streams reports codec_name=webp on a libwebp-encoded WEBP
# @description: Encodes a PNG to WEBP through ffmpeg's libwebp encoder, then runs ffprobe with -show_streams in default key=value format and asserts the codec_name line equals 'webp', confirming the libwebp-produced file is identified as the webp codec.
# @timeout: 180
# @tags: usage, ffmpeg, webp, codec-name, r19
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (50, 40), (10, 80, 160))
img.save(sys.argv[1])
PY

ffmpeg -hide_banner -y -i "$tmpdir/in.png" -vcodec libwebp -q:v 70 "$tmpdir/out.webp" >"$tmpdir/ff.log" 2>&1

ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=0:noprint_wrappers=1 "$tmpdir/out.webp" >"$tmpdir/probe.txt"
grep -q '^codec_name=webp$' "$tmpdir/probe.txt" || {
    echo "expected codec_name=webp" >&2
    cat "$tmpdir/probe.txt" >&2
    exit 1
}
