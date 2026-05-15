#!/usr/bin/env bash
# @testcase: usage-vips-r19-webpsave-q-100-non-empty-output
# @title: vips webpsave --Q 100 produces a non-empty WEBP that vipsheader reports as RGB
# @description: Encodes a PPM through vips webpsave at maximum quality --Q 100, asserts the output is identified as WEBP by file(1), is non-empty, and that vipsheader reports bands=3 confirming the libwebp encoder produced a regular RGB stream.
# @timeout: 120
# @tags: usage, vips, webp, q-max, r19
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 48, 36
data = bytes([(((x ^ y) * 7) & 0xff)
              for y in range(h) for x in range(w * 3)])
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/out.webp" --Q 100
test -s "$tmpdir/out.webp"
file "$tmpdir/out.webp" | grep -q 'Web/P'

bands=$(vipsheader -f bands "$tmpdir/out.webp")
[[ "$bands" == "3" ]] || { printf 'expected bands=3, got %s\n' "$bands" >&2; exit 1; }
