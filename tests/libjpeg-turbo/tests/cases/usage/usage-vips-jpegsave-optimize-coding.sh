#!/usr/bin/env bash
# @testcase: usage-vips-jpegsave-optimize-coding
# @title: vips jpegsave optimize-coding shrinks bytes
# @description: Encodes the same JPEG twice with vips jpegsave at Q=85 — once with --no-optimize-coding, once with --optimize-coding — and confirms the optimised output is no larger and remains a valid JPEG.
# @timeout: 180
# @tags: usage, jpeg, image, encoder
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
W, H = 32, 32
pixels = bytearray()
for y in range(H):
    for x in range(W):
        pixels += bytes((((x * 7) ^ (y * 3)) & 255, (x * 5 + y) & 255, ((x + y * 2)) & 255))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + bytes(pixels))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vips jpegsave "$tmpdir/in.jpg" "$tmpdir/plain.jpg"     --Q 85 --no-optimize-coding
vips jpegsave "$tmpdir/in.jpg" "$tmpdir/optimal.jpg"   --Q 85 --optimize-coding

plain_size=$(wc -c <"$tmpdir/plain.jpg")
opt_size=$(wc -c <"$tmpdir/optimal.jpg")
echo "plain=$plain_size optimised=$opt_size"
[ "$opt_size" -le "$plain_size" ] || {
    echo "optimize-coding produced larger output ($opt_size > $plain_size)" >&2
    exit 1
}

file "$tmpdir/optimal.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
