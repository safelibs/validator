#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r14-pixdata-rgb-magic-and-size
# @title: gdk-pixbuf-pixdata on an RGB WebP emits a 'GdkP' blob larger than its input
# @description: Saves a small RGB WebP via Pillow, runs gdk-pixbuf-pixdata over it, and asserts the resulting GdkPixdata blob starts with the four-byte 'GdkP' magic and is at least the size of an uncompressed pixmap raster (width*height*3 bytes), confirming the WebP loader produced a fully-decoded pixbuf payload.
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
img = Image.new('RGB', (16, 12), (90, 180, 60))
img.save(sys.argv[1], 'WEBP', quality=85)
PY

file "$tmpdir/in.webp" | grep -q 'Web/P'

gdk-pixbuf-pixdata "$tmpdir/in.webp" "$tmpdir/out.gdkp"
[[ -s "$tmpdir/out.gdkp" ]]
head -c 4 "$tmpdir/out.gdkp" | od -An -tx1 | tr -d ' \n' | grep -q '^47646b50$'

sz=$(stat -c '%s' "$tmpdir/out.gdkp")
floor=$((16 * 12 * 3))
[[ "$sz" -ge "$floor" ]] || {
    printf 'pixdata size %s below pixmap floor %s\n' "$sz" "$floor" >&2
    exit 1
}
