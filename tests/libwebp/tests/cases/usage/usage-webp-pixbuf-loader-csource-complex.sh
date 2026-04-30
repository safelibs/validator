#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-csource-complex
# @title: gdk-pixbuf-csource on a complex WebP
# @description: Encodes a larger varied-pattern WebP through cwebp and runs gdk-pixbuf-csource on it to confirm the WebP pixbuf loader decodes a non-trivial image and gdk-pixbuf-csource emits the GdkPixdata header with the expected width, height, and named array.
# @timeout: 180
# @tags: usage, webp, pixbuf
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a 16x12 RGB PPM with a varied gradient + checker pattern so the
# WebP encoder produces non-trivial structure for the loader to decode.
python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
W, H = 16, 12
pixels = bytearray()
for y in range(H):
    for x in range(W):
        r = (x * 17 + y * 5) & 0xff
        g = (x * 31 + y * 11) & 0xff
        b = (x * 7 + y * 23) & 0xff
        if (x // 2 + y // 2) % 2 == 0:
            r ^= 0x55
        pixels += bytes((r, g, b))
header = f"P6\n{W} {H}\n255\n".encode()
Path(sys.argv[1]).write_bytes(header + bytes(pixels))
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
file "$tmpdir/in.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

gdk-pixbuf-csource --raw --name=webp_complex "$tmpdir/in.webp" >"$tmpdir/out.c"
validator_require_file "$tmpdir/out.c"
test "$(wc -c <"$tmpdir/out.c")" -gt 0

# Named array, GdkPixdata magic, source dimensions decoded by the WebP loader.
validator_assert_contains "$tmpdir/out.c" 'webp_complex[]'
validator_assert_contains "$tmpdir/out.c" 'Pixbuf magic'
validator_assert_contains "$tmpdir/out.c" 'GdkP'
validator_assert_contains "$tmpdir/out.c" 'width (16)'
validator_assert_contains "$tmpdir/out.c" 'height (12)'
