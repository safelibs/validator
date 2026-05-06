#!/usr/bin/env bash
# @testcase: usage-vips-r11-gaussblur-jpeg
# @title: vips gaussblur smooths a JPEG and preserves geometry
# @description: Loads a JPEG, runs vips gaussblur with a small sigma to apply a Gaussian smoothing kernel, re-encodes as JPEG, and asserts the output keeps the original width, height, and band count via vipsheader.
# @timeout: 90
# @tags: usage, jpeg, image, gaussblur
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 40, 32
data = bytes([(i * 17) & 0xFF for i in range(w * h * 3)])
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips gaussblur "$tmpdir/in.jpg" "$tmpdir/out.jpg" 1.5

vipsheader -a "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 40'
validator_assert_contains "$tmpdir/hdr" 'height: 32'
validator_assert_contains "$tmpdir/hdr" 'bands: 3'
file "$tmpdir/out.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
