#!/usr/bin/env bash
# @testcase: usage-vips-r15-jpegsave-optimize-coding-no-larger
# @title: vips jpegsave --optimize-coding yields a no-larger file than the default
# @description: Encodes the same PPM through vips jpegsave with and without --optimize-coding at constant Q and asserts the optimised output is no larger than the default, exercising libjpeg-turbo's optimise-Huffman path through vips.
# @timeout: 180
# @tags: usage, vips, jpeg, optimize
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

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/plain.jpg" --Q 85
vips jpegsave "$tmpdir/in.ppm" "$tmpdir/opt.jpg" --Q 85 --optimize-coding

file "$tmpdir/plain.jpg" | grep -q 'JPEG image data'
file "$tmpdir/opt.jpg" | grep -q 'JPEG image data'

a=$(wc -c <"$tmpdir/plain.jpg")
b=$(wc -c <"$tmpdir/opt.jpg")
[[ "$b" -le "$a" ]] || {
    printf 'expected --optimize-coding (%s) <= default (%s)\n' "$b" "$a" >&2
    exit 1
}
