#!/usr/bin/env bash
# @testcase: usage-vips-r12-jpegsave-q-low-vs-high-size
# @title: vips jpegsave --Q 10 yields a smaller file than --Q 95
# @description: Encodes a synthetic PPM through vips jpegsave at --Q 10 and --Q 95 and asserts the low-Q file is strictly smaller, exercising the libjpeg-turbo lossy quality scale via vips.
# @timeout: 60
# @tags: usage, jpeg, image, quality
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 96, 64
data = bytes([(((x * 11) ^ (y * 7)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/lo.jpg" --Q 10
vips jpegsave "$tmpdir/in.ppm" "$tmpdir/hi.jpg" --Q 95

file "$tmpdir/lo.jpg" >"$tmpdir/lo.file" && validator_assert_contains "$tmpdir/lo.file" 'JPEG image data'
file "$tmpdir/hi.jpg" >"$tmpdir/hi.file" && validator_assert_contains "$tmpdir/hi.file" 'JPEG image data'

lo=$(wc -c <"$tmpdir/lo.jpg")
hi=$(wc -c <"$tmpdir/hi.jpg")
[[ "$lo" -lt "$hi" ]] || {
    printf 'expected lo (%s) < hi (%s)\n' "$lo" "$hi" >&2
    exit 1
}
