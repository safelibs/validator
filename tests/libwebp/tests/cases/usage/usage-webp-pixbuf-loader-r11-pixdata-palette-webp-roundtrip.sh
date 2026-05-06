#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r11-pixdata-palette-webp-roundtrip
# @title: gdk-pixbuf-pixdata decodes a palette-encoded WebP via the webp loader
# @description: Saves a P-mode (palette) lossless WebP via Pillow then runs gdk-pixbuf-pixdata to convert it to a GdkPixdata blob, asserting the loader emits a non-empty stream beginning with the 'GdkP' magic.
# @timeout: 180
# @tags: usage, webp-pixbuf-loader, webp
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/pal.webp"
import sys
from PIL import Image

img = Image.new('P', (12, 12))
img.putpalette([0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255] + [0] * (256 * 3 - 12))
img.save(sys.argv[1], 'WEBP', lossless=True)
PY

# Sanity-check the source is a real WebP before exercising the loader.
file "$tmpdir/pal.webp" | grep -q 'Web/P'

gdk-pixbuf-pixdata "$tmpdir/pal.webp" "$tmpdir/out.gdkp"
[[ -s "$tmpdir/out.gdkp" ]]
head -c 4 "$tmpdir/out.gdkp" | od -An -tx1 | tr -d ' \n' | grep -q '^47646b50$'
