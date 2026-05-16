#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r21-gdk-pixbuf-pixdata-runs-on-webp
# @title: gdk-pixbuf-pixdata reads a WEBP via the webp-pixbuf-loader and emits a non-empty GdkPixdata struct
# @description: Encodes a small RGB WEBP via Pillow and runs gdk-pixbuf-pixdata on it, asserting the binary GdkPixdata output is non-empty — pinning the webp-pixbuf-loader's bridging into gdk-pixbuf-pixdata on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, webp-pixbuf-loader, pixdata, r21
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

command -v gdk-pixbuf-pixdata >/dev/null 2>&1 || { echo "gdk-pixbuf-pixdata not available" >&2; exit 1; }

python3 - "$tmpdir/in.webp" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (32, 24), (10, 200, 70))
img.save(sys.argv[1], 'WEBP', quality=80)
PY

gdk-pixbuf-pixdata "$tmpdir/in.webp" "$tmpdir/out.gdkp"
[[ -s "$tmpdir/out.gdkp" ]] || { echo "expected non-empty GdkPixdata output" >&2; exit 1; }
# GdkPixdata starts with magic 0x47646b50 ('GdkP')
head -c 4 "$tmpdir/out.gdkp" | grep -q 'GdkP' || {
    echo "expected GdkP magic at start of pixdata output" >&2
    od -An -c -N 16 "$tmpdir/out.gdkp" >&2
    exit 1
}
