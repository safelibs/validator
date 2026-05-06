#!/usr/bin/env bash
# @testcase: usage-vips-r11-cast-uchar-jpeg
# @title: vips cast to uchar preserves JPEG geometry and band count
# @description: Loads a JPEG and runs vips cast with the uchar target type, then re-encodes as JPEG, asserting the output keeps the same width, height, and band count via vipsheader and is still recognised as JPEG by file(1).
# @timeout: 60
# @tags: usage, jpeg, image, cast
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 36, 28
data = bytes([(i * 11) & 0xFF for i in range(w * h * 3)])
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips cast "$tmpdir/in.jpg" "$tmpdir/out.jpg" uchar

vipsheader -a "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 36'
validator_assert_contains "$tmpdir/hdr" 'height: 28'
validator_assert_contains "$tmpdir/hdr" 'bands: 3'
validator_assert_contains "$tmpdir/hdr" 'format: uchar'
file "$tmpdir/out.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
