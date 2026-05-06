#!/usr/bin/env bash
# @testcase: usage-vips-r10-affine-identity-jpeg
# @title: vips affine identity transform preserves JPEG dimensions
# @description: Applies the identity affine matrix (1, 0, 0, 1) to a JPEG via vips affine and verifies the result has the same dimensions and decodes back as a valid JPEG with vipsheader.
# @timeout: 180
# @tags: usage, jpeg, image, affine
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 48, 24
data = bytes([(i * 5) & 0xFF for i in range(w * h * 3)])
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips affine "$tmpdir/in.jpg" "$tmpdir/out.jpg" "1 0 0 1"

vipsheader -a "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 48'
validator_assert_contains "$tmpdir/hdr" 'height: 24'

file "$tmpdir/out.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
