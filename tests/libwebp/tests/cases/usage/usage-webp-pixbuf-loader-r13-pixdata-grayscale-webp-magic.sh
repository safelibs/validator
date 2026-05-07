#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r13-pixdata-grayscale-webp-magic
# @title: gdk-pixbuf-pixdata decodes a grayscale-derived RGB WebP via the webp loader
# @description: Builds an L-mode (grayscale) Pillow image, converts to RGB, saves as WebP, then runs gdk-pixbuf-pixdata over it and asserts the resulting GdkPixdata blob starts with the four-byte 'GdkP' magic, confirming the loader handled the WebP via the webp-pixbuf-loader plugin.
# @timeout: 180
# @tags: usage, webp-pixbuf-loader, webp
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/g.webp"
import sys
from PIL import Image
gray = Image.new('L', (16, 12))
for y in range(12):
    for x in range(16):
        gray.putpixel((x, y), (x * 17 + y * 11) & 0xff)
gray.convert('RGB').save(sys.argv[1], 'WEBP', quality=85)
PY

file "$tmpdir/g.webp" | grep -q 'Web/P'

gdk-pixbuf-pixdata "$tmpdir/g.webp" "$tmpdir/out.gdkp"
[[ -s "$tmpdir/out.gdkp" ]]
head -c 4 "$tmpdir/out.gdkp" | od -An -tx1 | tr -d ' \n' | grep -q '^47646b50$'
