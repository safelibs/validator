#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-null-output
# @title: ffmpeg WebP null output
# @description: Decodes WebP input through ffmpeg null output mode and verifies processing statistics are printed.
# @timeout: 180
# @tags: usage, webp, video
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ffmpeg-webp-null-output"
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
ffmpeg -hide_banner -loglevel info -i "$tmpdir/in.webp" -f null - >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'video:'
