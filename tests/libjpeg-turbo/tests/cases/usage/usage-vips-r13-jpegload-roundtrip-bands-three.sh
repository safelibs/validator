#!/usr/bin/env bash
# @testcase: usage-vips-r13-jpegload-roundtrip-bands-three
# @title: vips jpegload reports 3 bands for an RGB JPEG
# @description: Builds an RGB JPEG via cjpeg, loads it with vips jpegload, and asserts vipsheader reports a bands=3 RGB header, exercising the standard libjpeg-turbo 3-component decode path.
# @timeout: 60
# @tags: usage, jpeg, image, decoder
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 48, 36
data = bytes([(((x * 5) ^ (y * 11)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
file "$tmpdir/in.jpg" | grep -q 'JPEG image data'

vips jpegload "$tmpdir/in.jpg" "$tmpdir/out.v"

vipsheader -a "$tmpdir/out.v" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'bands: 3'
validator_assert_contains "$tmpdir/hdr" 'width: 48'
validator_assert_contains "$tmpdir/hdr" 'height: 36'
