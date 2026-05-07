#!/usr/bin/env bash
# @testcase: usage-vips-r12-webpsave-q-low-vs-high-size
# @title: vips webpsave --Q 10 yields a smaller file than --Q 95
# @description: Encodes a synthetic RGB image through vips webpsave at --Q 10 and --Q 95 and asserts the low-Q file is strictly smaller and both files are recognised as WebP, exercising the lossy quality scale.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 96, 64
data = bytes([(((x * 11) ^ (y * 7)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/lo.webp" --Q 10
vips webpsave "$tmpdir/in.ppm" "$tmpdir/hi.webp" --Q 95

file "$tmpdir/lo.webp" | grep -q 'Web/P'
file "$tmpdir/hi.webp" | grep -q 'Web/P'

lo=$(wc -c <"$tmpdir/lo.webp")
hi=$(wc -c <"$tmpdir/hi.webp")
[[ "$lo" -lt "$hi" ]] || {
    printf 'expected lo (%s) < hi (%s)\n' "$lo" "$hi" >&2
    exit 1
}
