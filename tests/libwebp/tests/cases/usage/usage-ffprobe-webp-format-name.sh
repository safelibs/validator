#!/usr/bin/env bash
# @testcase: usage-ffprobe-webp-format-name
# @title: ffprobe WebP format metadata
# @description: Runs ffprobe on a WebP fixture and validates the demuxer-reported format name and codec name surface as 'webp'.
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

ffprobe -hide_banner -loglevel error \
  -show_entries format=format_name -of csv=p=0 "$tmpdir/in.webp" \
  | tee "$tmpdir/format"
validator_assert_contains "$tmpdir/format" 'webp'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=codec_name -of csv=p=0 "$tmpdir/in.webp" \
  | tee "$tmpdir/codec"
codec=$(tr -d '[:space:]' <"$tmpdir/codec")
test "$codec" = "webp"
