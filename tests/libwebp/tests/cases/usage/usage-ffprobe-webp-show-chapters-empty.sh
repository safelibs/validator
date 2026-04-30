#!/usr/bin/env bash
# @testcase: usage-ffprobe-webp-show-chapters-empty
# @title: ffprobe -show_chapters on still WebP is empty
# @description: A still WebP image has no chapter markers, so ffprobe -show_chapters must succeed and emit no [CHAPTER] sections. This testcase encodes a PNG to WebP with ffmpeg and then verifies the chapter listing is empty while format/stream info is still readable.
# @timeout: 180
# @tags: usage, webp, ffprobe
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
from PIL import Image
import sys
im = Image.new("RGB", (6, 5), (0, 0, 0))
for y in range(5):
    for x in range(6):
        im.putpixel((x, y), ((x * 19) % 256, (y * 53) % 256, ((x + y) * 7) % 256))
im.save(sys.argv[1], "PNG")
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.png" \
  -c:v libwebp "$tmpdir/in.webp"
validator_require_file "$tmpdir/in.webp"

ffprobe -hide_banner -loglevel error -show_chapters "$tmpdir/in.webp" >"$tmpdir/chapters" 2>&1 || {
  cat "$tmpdir/chapters" >&2
  exit 1
}
cat "$tmpdir/chapters"
# A still WebP must not produce any [CHAPTER]/[/CHAPTER] sections.
if grep -F '[CHAPTER]' "$tmpdir/chapters" >/dev/null; then
  echo "unexpected [CHAPTER] section in still WebP" >&2
  exit 1
fi

# Sanity: format/stream info is still readable on the same file.
ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=, "$tmpdir/in.webp" | tee "$tmpdir/dims"
grep -Fxq '6,5' "$tmpdir/dims"
