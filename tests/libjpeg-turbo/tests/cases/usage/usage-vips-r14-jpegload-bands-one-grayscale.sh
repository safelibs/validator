#!/usr/bin/env bash
# @testcase: usage-vips-r14-jpegload-bands-one-grayscale
# @title: vips jpegload reports bands=1 for a grayscale JPEG
# @description: Builds a grayscale JPEG via cjpeg from a PGM source, loads it with vips jpegload, and asserts vipsheader reports a 1-band single-channel header, exercising the libjpeg-turbo grayscale (Y-only) decode path through vips.
# @timeout: 180
# @tags: usage, jpeg, image, grayscale
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.pgm"
import sys
w, h = 32, 24
data = bytes([(x * 7 + y * 11) & 0xff for y in range(h) for x in range(w)])
open(sys.argv[1], 'wb').write(f'P5\n{w} {h}\n255\n'.encode() + data)
PY

cjpeg -grayscale "$tmpdir/in.pgm" >"$tmpdir/in.jpg"
file "$tmpdir/in.jpg" | grep -q 'JPEG image data'

vips jpegload "$tmpdir/in.jpg" "$tmpdir/out.v"
vipsheader -a "$tmpdir/out.v" >"$tmpdir/hdr.txt"
validator_assert_contains "$tmpdir/hdr.txt" 'bands: 1'
validator_assert_contains "$tmpdir/hdr.txt" 'width: 32'
validator_assert_contains "$tmpdir/hdr.txt" 'height: 24'
