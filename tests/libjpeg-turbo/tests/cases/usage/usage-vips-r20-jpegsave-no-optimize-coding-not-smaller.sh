#!/usr/bin/env bash
# @testcase: usage-vips-r20-jpegsave-no-optimize-coding-not-smaller
# @title: vips jpegsave default (no --optimize-coding) is not smaller than --optimize-coding
# @description: Encodes the same PPM to JPEG via vips jpegsave twice at Q=85 — once with the default optimize-coding=false and once with --optimize-coding (true) — and asserts the default-mode output size is greater than or equal to the optimize-coding output size, exercising libjpeg-turbo's Huffman optimization toggle through vips' boolean flag.
# @timeout: 180
# @tags: usage, vips, jpeg, optimize-coding, size, r20
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

W=96; H=64
{
  printf 'P6\n%d %d\n255\n' "$W" "$H"
  python3 -c "import sys
W, H = $W, $H
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 13) & 255, (y * 7) & 255, ((x ^ y) * 5) & 255))
sys.stdout.buffer.write(b)
"
} >"$tmpdir/in.ppm"

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/opt.jpg" --Q 85 --optimize-coding
vips jpegsave "$tmpdir/in.ppm" "$tmpdir/noopt.jpg" --Q 85

s_opt=$(wc -c <"$tmpdir/opt.jpg")
s_noopt=$(wc -c <"$tmpdir/noopt.jpg")
if [[ "$s_noopt" -lt "$s_opt" ]]; then
  printf 'expected default (%s) >= optimize-coding (%s)\n' "$s_noopt" "$s_opt" >&2
  exit 1
fi
