#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-pixdata-name
# @title: gdk-pixbuf WebP pixdata --rle binary header
# @description: Loads a WebP fixture via gdk-pixbuf-pixdata with --rle (RLE compression on) and verifies the produced pixdata blob exists, is non-empty, and starts with the GdkPixdata magic ("GdkP", 0x47646b50) confirming the WebP pixbuf loader fed real pixels through the pixdata serializer.
# @timeout: 180
# @tags: usage, webp, pixbuf
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
W, H = 8, 6
pixels = bytearray()
for y in range(H):
    for x in range(W):
        # Smooth gradient that compresses well under RLE.
        v = (x * 32) & 0xff
        pixels += bytes((v, v, v))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + bytes(pixels))
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"

gdk-pixbuf-pixdata --rle "$tmpdir/in.webp" "$tmpdir/out.pixdata"
validator_require_file "$tmpdir/out.pixdata"
test "$(wc -c <"$tmpdir/out.pixdata")" -gt 0

# Verify GdkPixdata magic is present at byte 0.
python3 - <<'PY' "$tmpdir/out.pixdata"
import sys
data = open(sys.argv[1], "rb").read()
# GdkPixdata magic: 'GdkP' = 0x47646b50, big-endian.
assert data[:4] == b"GdkP", data[:4].hex()
print("pixdata-rle magic OK, len=", len(data))
PY
