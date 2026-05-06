#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-tiff2pdf-jpeg-output
# @title: tiff2pdf -j packs a Pillow JPEG-compressed TIFF into a PDF
# @description: Saves a JPEG-compressed RGB TIFF with Pillow, runs tiff2pdf -j to wrap it as a PDF, and verifies the output begins with the %PDF-1 magic and ends with the %%EOF trailer.
# @timeout: 180
# @tags: usage, tiff, python, tiff2pdf
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/in.tiff"
pdf="$tmpdir/out.pdf"

python3 - "$src" <<'PY'
import sys
from PIL import Image
img = Image.new("RGB", (40, 32))
img.putdata([((x * 7) % 256, (y * 11) % 256, ((x + y) * 5) % 256)
             for y in range(32) for x in range(40)])
img.save(sys.argv[1], "TIFF", compression="jpeg", quality=80)
PY

validator_require_file "$src"
tiff2pdf -j -o "$pdf" "$src"
validator_require_file "$pdf"

head -c 5 "$pdf" | grep -q '^%PDF-'
tail -c 64 "$pdf" | grep -q '%%EOF'
