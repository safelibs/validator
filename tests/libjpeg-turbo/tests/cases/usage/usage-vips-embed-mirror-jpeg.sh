#!/usr/bin/env bash
# @testcase: usage-vips-embed-mirror-jpeg
# @title: vips embed extend mirror JPEG
# @description: Embeds a JPEG into a larger canvas using vips embed --extend mirror and verifies the resulting dimensions and band count via vipsheader -a.
# @timeout: 180
# @tags: usage, jpeg, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-vips-embed-mirror-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
header = b"P6\n16 16\n255\n"
pixels = bytes([128] * (16 * 16 * 3))
Path(sys.argv[1]).write_bytes(header + pixels)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vipsheader -a "$tmpdir/in.jpg" | tee "$tmpdir/in.header"
validator_assert_contains "$tmpdir/in.header" 'width: 16'

vips embed "$tmpdir/in.jpg" "$tmpdir/embed.png" 4 4 32 32 --extend mirror
validator_require_file "$tmpdir/embed.png"
vipsheader -a "$tmpdir/embed.png" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'width: 32'
validator_assert_contains "$tmpdir/header" 'height: 32'
validator_assert_contains "$tmpdir/header" 'bands: 3'
