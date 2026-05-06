#!/usr/bin/env bash
# @testcase: usage-vips-r9-jpegload-bands-rgb
# @title: vips jpegload reports 3 bands for RGB JPEG
# @description: Loads an RGB JPEG with vips jpegload and uses vipsheader to verify the image reports exactly three bands.
# @timeout: 180
# @tags: usage, jpeg, image, bands
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
data = bytes([200, 100, 50, 50, 100, 200, 100, 200, 50, 50, 200, 100])
open(sys.argv[1], "wb").write(b"P6\n2 2\n255\n" + data)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vips jpegload "$tmpdir/in.jpg" "$tmpdir/out.v"
bands=$(vipsheader -f bands "$tmpdir/out.v")
[[ "$bands" == "3" ]] || {
  printf 'expected 3 bands, got %s\n' "$bands" >&2
  exit 1
}
