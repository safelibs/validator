#!/usr/bin/env bash
# @testcase: usage-vips-r17-webpsave-preset-picture-flag-accepted
# @title: vips webpsave --preset picture flag is accepted and produces a valid WEBP file
# @description: Encodes a PPM via vips webpsave with the --preset picture flag, asserts the resulting file is identified as WEBP by file(1), and confirms dims round-trip via vipsheader.
# @timeout: 120
# @tags: usage, vips, webp, preset
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 72, 56
data = bytes([(((x * 9) + (y * 5)) & 0xff)
              for y in range(h) for x in range(w * 3)])
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/out.webp" --Q 75 --preset picture
file "$tmpdir/out.webp" | grep -q 'Web/P'

w_out=$(vipsheader -f width "$tmpdir/out.webp")
h_out=$(vipsheader -f height "$tmpdir/out.webp")
[[ "$w_out" == "72" && "$h_out" == "56" ]] || {
    printf 'unexpected dims %sx%s\n' "$w_out" "$h_out" >&2
    exit 1
}
