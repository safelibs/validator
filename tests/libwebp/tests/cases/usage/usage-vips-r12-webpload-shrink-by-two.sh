#!/usr/bin/env bash
# @testcase: usage-vips-r12-webpload-shrink-by-two
# @title: vips webpload --shrink 2 halves WebP output dimensions
# @description: Builds a 64x48 RGB WebP via Pillow and loads it through vips webpload --shrink 2, asserting the loaded image is exactly 32x24, exercising the integer-shrink decode path.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
img = Image.new('RGB', (64, 48), (120, 60, 200))
img.save(sys.argv[1], 'WEBP', quality=85)
PY

vips webpload "$tmpdir/in.webp" "$tmpdir/half.png" --shrink 2
w=$(vipsheader -f width  "$tmpdir/half.png")
h=$(vipsheader -f height "$tmpdir/half.png")
[[ "$w" -eq 32 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 24 ]] || { echo "height $h" >&2; exit 1; }
