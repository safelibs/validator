#!/usr/bin/env bash
# @testcase: usage-vips-r10-sharpen-jpeg
# @title: vips sharpen on a JPEG produces a valid JPEG
# @description: Loads a JPEG, applies vips sharpen with a small sigma, re-encodes the result with jpegsave, and verifies the output is a JPEG with the original dimensions.
# @timeout: 180
# @tags: usage, jpeg, image, sharpen
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 32, 32
data = bytes([(((x * 11) ^ (y * 13)) & 0xFF) for x in range(w * h * 3)])
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips sharpen "$tmpdir/in.jpg" "$tmpdir/sharp.v" --sigma 0.5
vips jpegsave "$tmpdir/sharp.v" "$tmpdir/out.jpg" --Q 85

vipsheader "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '32x32'

file "$tmpdir/out.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
