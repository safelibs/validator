#!/usr/bin/env bash
# @testcase: usage-vips-r11-webpsave-near-lossless-flag
# @title: vips webpsave --near-lossless emits a structurally valid WebP
# @description: Encodes an RGB image through vips webpsave with --near-lossless and a low Q, then verifies the output is a valid WebP that decodes back to the original geometry.
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
src = Image.new('RGB', (40, 30), (100, 150, 200))
src.save(sys.argv[1], 'WEBP', quality=80)
PY

vips webpsave "$tmpdir/in.webp" "$tmpdir/nl.webp" --near-lossless --Q 60
file "$tmpdir/nl.webp" | grep -q 'Web/P'

w=$(vipsheader -f width "$tmpdir/nl.webp")
h=$(vipsheader -f height "$tmpdir/nl.webp")
[[ "$w" -eq 40 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 30 ]] || { echo "height $h" >&2; exit 1; }
