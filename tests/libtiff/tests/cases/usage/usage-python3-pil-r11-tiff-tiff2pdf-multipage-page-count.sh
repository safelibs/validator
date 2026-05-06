#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-tiff2pdf-multipage-page-count
# @title: tiff2pdf produces a PDF whose page count matches the multi-page TIFF
# @description: Builds a 4-page TIFF with Pillow save_all + append_images, runs tiff2pdf, and verifies pdfinfo reports exactly Pages: 4 in the output PDF.
# @timeout: 120
# @tags: usage, tiff, tiff2pdf, multipage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/multi.tif"
out="$tmpdir/out.pdf"

python3 - "$src" <<'PY'
import sys
from PIL import Image
im = Image.new('RGB', (24, 16), (10, 20, 30))
im.save(sys.argv[1], 'TIFF', save_all=True, append_images=[im, im, im])
PY

tiff2pdf -o "$out" "$src" >/dev/null 2>&1
pdfinfo "$out" >"$tmpdir/info.out"
grep -E '^Pages:[[:space:]]+4$' "$tmpdir/info.out" >/dev/null
