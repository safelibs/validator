#!/usr/bin/env bash
# @testcase: usage-vips-r16-webpsave-effort-zero-vs-six-monotonic
# @title: vips webpsave effort=6 produces a file no larger than effort=0 at fixed --Q
# @description: Encodes the same PPM through vips webpsave at --Q 70 with effort=0 (fastest) and effort=6 (best), and asserts the effort=6 file size is no larger than the effort=0 file, exercising libwebp's method/effort knob's monotonic size effect via vips.
# @timeout: 180
# @tags: usage, vips, webp, effort
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 72, 56
data = bytes([(((x * 13) + (y * 9)) & 0xff)
              for y in range(h) for x in range(w * 3)])
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/e0.webp" --Q 70 --effort 0
vips webpsave "$tmpdir/in.ppm" "$tmpdir/e6.webp" --Q 70 --effort 6

file "$tmpdir/e0.webp" | grep -q 'Web/P'
file "$tmpdir/e6.webp" | grep -q 'Web/P'

s0=$(wc -c <"$tmpdir/e0.webp")
s6=$(wc -c <"$tmpdir/e6.webp")
[[ "$s6" -le "$s0" ]] || {
    printf 'expected effort=6 (%s) <= effort=0 (%s)\n' "$s6" "$s0" >&2
    exit 1
}
