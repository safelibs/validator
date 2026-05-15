#!/usr/bin/env bash
# @testcase: usage-vips-r20-rot90-then-rot270-restores-dims
# @title: vips rot d90 then rot d270 on a JPEG restores original (W,H) dimensions
# @description: Encodes a 40x24 PPM to JPEG via vips jpegsave, rotates by 90 degrees, rotates the result by 270 degrees, and asserts the final image's (width,height) match the source (40,24), exercising libjpeg-turbo encode/decode through a vips rotate-and-back round-trip.
# @timeout: 180
# @tags: usage, vips, jpeg, rot, roundtrip, r20
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

W=40; H=24
{
  printf 'P6\n%d %d\n255\n' "$W" "$H"
  python3 -c "import sys
W, H = $W, $H
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 9) & 255, (y * 11) & 255, ((x + y) * 5) & 255))
sys.stdout.buffer.write(b)
"
} >"$tmpdir/in.ppm"

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/src.jpg"
vips rot "$tmpdir/src.jpg" "$tmpdir/r1.v" d90
vips rot "$tmpdir/r1.v" "$tmpdir/r2.v" d270

w2=$(vipsheader -f width "$tmpdir/r2.v")
h2=$(vipsheader -f height "$tmpdir/r2.v")
[[ "$w2" == "$W" ]] || { printf 'expected width %s, got %s\n' "$W" "$w2" >&2; exit 1; }
[[ "$h2" == "$H" ]] || { printf 'expected height %s, got %s\n' "$H" "$h2" >&2; exit 1; }
