#!/usr/bin/env bash
# @testcase: usage-vips-r20-webpsave-lossless-flag-reports-vipsheader-dims
# @title: vips webpsave with --lossless writes a WEBP whose vipsheader width/height match the source
# @description: Encodes a 50x40 PPM to WEBP via vips webpsave --lossless and asserts vipsheader -f width and -f height on the resulting WEBP report 50 and 40 respectively, pinning libwebp's lossless-mode dimension preservation through vips.
# @timeout: 120
# @tags: usage, vips, webp, lossless, vipsheader, r20
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 50, 40
data = bytes((((x * 5) + (y * 11)) & 0xff)
              for y in range(h) for x in range(w * 3))
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/out.webp" --lossless

w_out=$(vipsheader -f width "$tmpdir/out.webp")
h_out=$(vipsheader -f height "$tmpdir/out.webp")
[[ "$w_out" == "50" ]] || { printf 'expected width 50, got %s\n' "$w_out" >&2; exit 1; }
[[ "$h_out" == "40" ]] || { printf 'expected height 40, got %s\n' "$h_out" >&2; exit 1; }
