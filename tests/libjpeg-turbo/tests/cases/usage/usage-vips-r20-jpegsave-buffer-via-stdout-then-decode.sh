#!/usr/bin/env bash
# @testcase: usage-vips-r20-jpegsave-buffer-via-stdout-then-decode
# @title: vips jpegsave to .jpg target then vipsheader reports the correct width
# @description: Builds a 48x32 PPM, encodes it via vips jpegsave at default quality, then runs vipsheader -f width on the produced .jpg and asserts the width equals 48, exercising libjpeg-turbo's encode followed by an immediate libjpeg-turbo decode through vipsheader.
# @timeout: 180
# @tags: usage, vips, jpeg, jpegsave, header, r20
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

W=48; H=32
{
  printf 'P6\n%d %d\n255\n' "$W" "$H"
  python3 -c "import sys
W, H = $W, $H
buf = bytearray()
for y in range(H):
    for x in range(W):
        buf += bytes(((x * 9) & 255, (y * 17) & 255, ((x + y) * 3) & 255))
sys.stdout.buffer.write(buf)
"
} >"$tmpdir/in.ppm"

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/out.jpg"
w=$(vipsheader -f width "$tmpdir/out.jpg")
[[ "$w" == "$W" ]] || { printf 'expected width %s, got %s\n' "$W" "$w" >&2; exit 1; }
