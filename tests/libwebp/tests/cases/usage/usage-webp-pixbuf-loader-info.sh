#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-info
# @title: gdk-pixbuf WebP info
# @description: Loads WebP input with gdk-pixbuf-pixdata and verifies pixbuf data output.
# @timeout: 180
# @tags: usage, webp, pixbuf
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-webp-pixbuf-loader-info"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_webp() {
  python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

make_webp
gdk-pixbuf-pixdata "$tmpdir/in.webp" "$tmpdir/out.pixdata"
validator_require_file "$tmpdir/out.pixdata"
test "$(wc -c <"$tmpdir/out.pixdata")" -gt 0
