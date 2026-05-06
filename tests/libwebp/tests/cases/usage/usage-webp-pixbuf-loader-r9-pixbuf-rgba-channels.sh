#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r9-pixbuf-rgba-channels
# @title: gdk-pixbuf-pixdata loads an RGBA WebP via the GdkPixbuf WebP loader
# @description: Encodes an RGBA WebP via Pillow then runs gdk-pixbuf-pixdata to convert it to a GdkPixdata blob, verifying the GdkPixbuf loader for image/webp can decode the file.
# @timeout: 180
# @tags: usage, webp-pixbuf-loader, webp
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
src = Image.new('RGBA', (16, 12), (10, 200, 60, 128))
src.save(sys.argv[1], 'WEBP', lossless=True)
PY

# gdk-pixbuf-query-loaders must list the WebP loader so update-mime cache picks it.
gdk-pixbuf-query-loaders >"$tmpdir/loaders.txt"
grep -Eqi '(WebP|webp)' "$tmpdir/loaders.txt"

# gdk-pixbuf-pixdata exercises the loader: it must decode the WebP and emit
# a GdkPixdata stream that begins with the well-known 'GdkP' magic.
gdk-pixbuf-pixdata "$tmpdir/in.webp" "$tmpdir/out.gdkp"
[[ -s "$tmpdir/out.gdkp" ]]
head -c 4 "$tmpdir/out.gdkp" | od -An -tx1 | tr -d ' \n' | grep -q '^47646b50'
