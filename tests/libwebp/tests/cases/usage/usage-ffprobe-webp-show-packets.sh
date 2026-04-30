#!/usr/bin/env bash
# @testcase: usage-ffprobe-webp-show-packets
# @title: ffprobe show_packets on WebP
# @description: Runs ffprobe -show_packets on a WebP fixture and verifies at least one packet is reported with codec_type=video.
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

ffprobe -hide_banner -loglevel error -show_packets \
  -of default=noprint_wrappers=0 "$tmpdir/in.webp" | tee "$tmpdir/packets"
validator_assert_contains "$tmpdir/packets" '[PACKET]'
validator_assert_contains "$tmpdir/packets" 'codec_type=video'
validator_assert_contains "$tmpdir/packets" '[/PACKET]'

# At least one [PACKET] block must be present.
count=$(grep -c '^\[PACKET\]$' "$tmpdir/packets")
test "$count" -ge 1
