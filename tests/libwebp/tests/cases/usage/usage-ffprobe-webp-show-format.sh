#!/usr/bin/env bash
# @testcase: usage-ffprobe-webp-show-format
# @title: ffprobe -show_format on WebP
# @description: Runs ffprobe with -show_format on a WebP fixture and verifies the [FORMAT] block plus a webp format_name surface in the output.
# @timeout: 180
# @tags: usage, webp, probe
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

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
validator_require_file "$tmpdir/in.webp"

ffprobe -hide_banner -loglevel error -show_format "$tmpdir/in.webp" \
  >"$tmpdir/format"
test -s "$tmpdir/format"
validator_assert_contains "$tmpdir/format" '[FORMAT]'
validator_assert_contains "$tmpdir/format" 'format_name='
validator_assert_contains "$tmpdir/format" 'webp'
validator_assert_contains "$tmpdir/format" '[/FORMAT]'
