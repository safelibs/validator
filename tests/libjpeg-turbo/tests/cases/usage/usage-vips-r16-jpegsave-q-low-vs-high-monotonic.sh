#!/usr/bin/env bash
# @testcase: usage-vips-r16-jpegsave-q-low-vs-high-monotonic
# @title: vips jpegsave Q=10 emits a strictly smaller file than Q=90 for the same PPM
# @description: Encodes the same generated PPM through vips jpegsave at Q=10 and Q=90 and asserts the Q=90 output is strictly larger than the Q=10 output, exercising libjpeg-turbo's quantisation scale via the vips --Q control.
# @timeout: 180
# @tags: usage, vips, jpeg, quality
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 96, 72
data = bytes([(((x * 7) ^ (y * 11)) & 0xff)
              for y in range(H) for x in range(W * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/q10.jpg" --Q 10
vips jpegsave "$tmpdir/in.ppm" "$tmpdir/q90.jpg" --Q 90

file "$tmpdir/q10.jpg" | grep -q 'JPEG image data'
file "$tmpdir/q90.jpg" | grep -q 'JPEG image data'

s10=$(wc -c <"$tmpdir/q10.jpg")
s90=$(wc -c <"$tmpdir/q90.jpg")
[[ "$s90" -gt "$s10" ]] || {
  printf 'expected Q90 (%s) > Q10 (%s)\n' "$s90" "$s10" >&2
  exit 1
}
