#!/usr/bin/env bash
# @testcase: usage-vips-r11-wrap-offset-jpeg
# @title: vips wrap shifts a JPEG with toroidal offset preserving geometry
# @description: Loads a JPEG and applies vips wrap with explicit x/y offsets to perform a toroidal pixel shift, then re-encodes as JPEG and asserts the output keeps the original width, height, and band count via vipsheader.
# @timeout: 60
# @tags: usage, jpeg, image, wrap
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 32, 24
data = bytes([(i * 13) & 0xFF for i in range(w * h * 3)])
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips wrap "$tmpdir/in.jpg" "$tmpdir/out.jpg" --x 10 --y 5

vipsheader -a "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 32'
validator_assert_contains "$tmpdir/hdr" 'height: 24'
validator_assert_contains "$tmpdir/hdr" 'bands: 3'
file "$tmpdir/out.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
