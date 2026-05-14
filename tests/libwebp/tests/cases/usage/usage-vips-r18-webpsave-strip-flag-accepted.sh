#!/usr/bin/env bash
# @testcase: usage-vips-r18-webpsave-strip-flag-accepted
# @title: vips webpsave --strip emits a valid WEBP file with matching dims
# @description: Encodes a PPM with vips webpsave --strip to drop ancillary metadata, asserts the output is identified as WEBP by file(1), and verifies vipsheader reports the source dimensions.
# @timeout: 120
# @tags: usage, vips, webp, strip, r18
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 64, 48
data = bytes([(((x * 5) + (y * 11)) & 0xff)
              for y in range(h) for x in range(w * 3)])
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/out.webp" --Q 70 --strip
file "$tmpdir/out.webp" | grep -q 'Web/P'

w_out=$(vipsheader -f width "$tmpdir/out.webp")
h_out=$(vipsheader -f height "$tmpdir/out.webp")
[[ "$w_out" == "64" && "$h_out" == "48" ]] || {
    printf 'unexpected dims %sx%s\n' "$w_out" "$h_out" >&2
    exit 1
}
