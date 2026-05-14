#!/usr/bin/env bash
# @testcase: usage-vips-r18-webpsave-effort-4-flag-accepted
# @title: vips webpsave with effort=4 produces a valid WEBP file
# @description: Encodes a PPM via vips webpsave with --effort=4, asserts the output is identified as WEBP by file(1), and asserts vipsheader reports the original PPM dimensions on read-back of the encoded WEBP.
# @timeout: 120
# @tags: usage, vips, webp, near-lossless, r18
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 56, 40
data = bytes([(((x ^ y) * 3) & 0xff)
              for y in range(h) for x in range(w * 3)])
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/out.webp" --effort=4
file "$tmpdir/out.webp" | grep -q 'Web/P'

w_out=$(vipsheader -f width "$tmpdir/out.webp")
h_out=$(vipsheader -f height "$tmpdir/out.webp")
[[ "$w_out" == "56" && "$h_out" == "40" ]] || {
    printf 'unexpected dims %sx%s\n' "$w_out" "$h_out" >&2
    exit 1
}
