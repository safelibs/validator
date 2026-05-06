#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r10-webp-preset-default
# @title: ffmpeg libwebp preset default produces a valid WebP
# @description: Encodes a PNG to WebP via ffmpeg using -preset default and asserts the output is a WebP that decodes at the source dimensions.
# @timeout: 180
# @tags: usage, ffmpeg, webp
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ffmpeg -loglevel error -y -f lavfi -i 'color=color=red:size=80x60:duration=1:rate=1' \
       -frames:v 1 "$tmpdir/in.png"

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -preset default \
       -frames:v 1 "$tmpdir/out.webp"

file "$tmpdir/out.webp" | grep -q 'Web/P'

python3 - <<'PY' "$tmpdir/out.webp"
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (80, 60), im.size
print('ok')
PY
