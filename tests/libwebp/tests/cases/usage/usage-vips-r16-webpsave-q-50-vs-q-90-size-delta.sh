#!/usr/bin/env bash
# @testcase: usage-vips-r16-webpsave-q-50-vs-q-90-size-delta
# @title: vips webpsave --Q 50 yields a strictly smaller file than --Q 90 on the same PPM source
# @description: Encodes the same generated PPM through vips webpsave at --Q 50 and --Q 90 and asserts the Q=50 output is strictly smaller than Q=90, exercising the lossy quality knob's size response on a mid-vs-high pair.
# @timeout: 120
# @tags: usage, vips, webp, quality
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 96, 72
data = bytes([(((x * 11) ^ (y * 7) + (x + y) * 3) & 0xff)
              for y in range(h) for x in range(w * 3)])
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/q50.webp" --Q 50
vips webpsave "$tmpdir/in.ppm" "$tmpdir/q90.webp" --Q 90

file "$tmpdir/q50.webp" | grep -q 'Web/P'
file "$tmpdir/q90.webp" | grep -q 'Web/P'

s50=$(wc -c <"$tmpdir/q50.webp")
s90=$(wc -c <"$tmpdir/q90.webp")
[[ "$s50" -lt "$s90" ]] || {
    printf 'expected Q=50 (%s) < Q=90 (%s)\n' "$s50" "$s90" >&2
    exit 1
}
