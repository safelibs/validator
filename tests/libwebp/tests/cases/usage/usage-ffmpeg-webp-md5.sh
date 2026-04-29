#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-md5
# @title: ffmpeg WebP MD5
# @description: Decodes WebP input through ffmpeg md5 muxing and checks digest output.
# @timeout: 180
# @tags: usage, webp, video
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ffmpeg-webp-md5"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_webp() {
  python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

make_webp
ffmpeg -hide_banner -loglevel error -i "$tmpdir/in.webp" -f md5 - >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'MD5='
