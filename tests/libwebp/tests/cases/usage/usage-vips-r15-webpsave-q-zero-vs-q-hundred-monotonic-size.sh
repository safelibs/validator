#!/usr/bin/env bash
# @testcase: usage-vips-r15-webpsave-q-zero-vs-q-hundred-monotonic-size
# @title: vips webpsave --Q 0 yields a file no larger than --Q 100 on the same source
# @description: Encodes the same PPM through vips webpsave at --Q 0 and --Q 100 and asserts the Q=0 output is no larger than Q=100, exercising the lossy quality-driven byte-size monotonicity through vips at the extreme endpoints.
# @timeout: 180
# @tags: usage, vips, webp, quality
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 64, 48
data = bytes([(((x * 9) ^ (y * 5)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/q0.webp" --Q 0
vips webpsave "$tmpdir/in.ppm" "$tmpdir/q100.webp" --Q 100

file "$tmpdir/q0.webp" | grep -q 'Web/P'
file "$tmpdir/q100.webp" | grep -q 'Web/P'

s0=$(wc -c <"$tmpdir/q0.webp")
s100=$(wc -c <"$tmpdir/q100.webp")
[[ "$s0" -le "$s100" ]] || {
    printf 'expected Q=0 (%s) <= Q=100 (%s)\n' "$s0" "$s100" >&2
    exit 1
}
