#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r12-pixdata-rgba-webp-magic-header
# @title: gdk-pixbuf-pixdata decodes an RGBA lossless WebP via the webp loader
# @description: Saves an RGBA lossless WebP via Pillow then runs gdk-pixbuf-pixdata to convert it to a GdkPixdata blob, asserting the loader emits a non-empty stream beginning with the four-byte 'GdkP' magic.
# @timeout: 180
# @tags: usage, webp-pixbuf-loader, webp
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/rgba.webp"
import sys
from PIL import Image
img = Image.new('RGBA', (12, 12), (200, 80, 40, 200))
img.save(sys.argv[1], 'WEBP', lossless=True)
PY

file "$tmpdir/rgba.webp" | grep -q 'Web/P'

gdk-pixbuf-pixdata "$tmpdir/rgba.webp" "$tmpdir/out.gdkp"
[[ -s "$tmpdir/out.gdkp" ]]
head -c 4 "$tmpdir/out.gdkp" | od -An -tx1 | tr -d ' \n' | grep -q '^47646b50$'
