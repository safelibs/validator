#!/usr/bin/env bash
# @testcase: usage-vips-r21-webpload-then-jpegsave-dimensions-preserved
# @title: vips webpload followed by jpegsave preserves width and height across the roundtrip
# @description: Encodes a PNG to WEBP via vips webpsave, then loads it with webpload and writes a JPEG, asserting the final JPEG reports the same width and height as the source — pinning libwebp decode dimensions through the vips pipeline on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, vips, webp, webpload, jpegsave, r21
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/src.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (96, 72), (60, 180, 240))
img.save(sys.argv[1], 'PNG')
PY

vips webpsave "$tmpdir/src.png" "$tmpdir/mid.webp" --Q 80
vips jpegsave "$tmpdir/mid.webp" "$tmpdir/out.jpg" --Q 85

w=$(vipsheader -f width "$tmpdir/out.jpg")
h=$(vipsheader -f height "$tmpdir/out.jpg")
[[ "$w" == "96" ]] || { printf 'expected width=96, got %s\n' "$w" >&2; exit 1; }
[[ "$h" == "72" ]] || { printf 'expected height=72, got %s\n' "$h" >&2; exit 1; }
