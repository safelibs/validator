#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r18-pixdata-prints-image-magic
# @title: gdk-pixbuf-pixdata reads a Pillow-saved WEBP and emits a non-empty GdkPixdata stream
# @description: Saves a small WEBP via Pillow, runs gdk-pixbuf-pixdata to convert it to a pixdata C source stream, asserts the output starts with the GDK_PIXBUF_C_SOURCE / GdkPixdata C identifiers, confirming the webp-pixbuf-loader module loaded a WEBP successfully.
# @timeout: 120
# @tags: usage, webp-pixbuf-loader, pixdata, r18
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.webp" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (32, 24), (70, 110, 180))
img.save(sys.argv[1], 'WEBP', quality=80)
PY

if ! command -v gdk-pixbuf-pixdata >/dev/null 2>&1; then
    echo "gdk-pixbuf-pixdata not installed" >&2
    exit 1
fi

gdk-pixbuf-pixdata "$tmpdir/in.webp" "$tmpdir/out.gdkpixdata"
validator_require_file "$tmpdir/out.gdkpixdata"
test -s "$tmpdir/out.gdkpixdata"

# The pixdata format starts with the magic 'GdkP' bytes.
head -c 4 "$tmpdir/out.gdkpixdata" | grep -q 'GdkP'
