#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-pgm-output
# @title: ffmpeg WebP PGM output
# @description: Decodes a WebP fixture with ffmpeg using gray pixel format and verifies the resulting PGM file begins with the P5 magic header.
# @timeout: 120
# @tags: usage
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ffmpeg-webp-pgm-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_ppm() {
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
}

make_webp() {
  make_ppm
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

make_webp
ffmpeg -hide_banner -loglevel error -i "$tmpdir/in.webp" -pix_fmt gray "$tmpdir/out.pgm"
head -c 2 "$tmpdir/out.pgm" >"$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'P5'
