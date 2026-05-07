#!/usr/bin/env bash
# @testcase: usage-vips-r14-jpegsave-q-low-vs-high-monotonic-size
# @title: vips jpegsave --Q 20 yields a smaller JPEG than --Q 90
# @description: Encodes the same PPM through vips jpegsave at --Q 20 and --Q 90 and asserts the low-Q output is strictly smaller than the high-Q output, exercising libjpeg-turbo's quality-driven byte-size monotonicity through vips.
# @timeout: 180
# @tags: usage, jpeg, image, quality
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 80, 60
data = bytes([(((x * 11) ^ (y * 7)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/lo.jpg" --Q 20
vips jpegsave "$tmpdir/in.ppm" "$tmpdir/hi.jpg" --Q 90

file "$tmpdir/lo.jpg" | grep -q 'JPEG image data'
file "$tmpdir/hi.jpg" | grep -q 'JPEG image data'

lo=$(wc -c <"$tmpdir/lo.jpg")
hi=$(wc -c <"$tmpdir/hi.jpg")
[[ "$lo" -lt "$hi" ]] || {
    printf 'expected lo (%s) < hi (%s)\n' "$lo" "$hi" >&2
    exit 1
}
