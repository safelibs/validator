#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiff2pdf-conversion
# @title: Pillow TIFF to PDF via tiff2pdf
# @description: Writes a TIFF with Pillow, converts it to PDF with tiff2pdf, and verifies the output starts with the %PDF- magic and is a non-empty file.
# @timeout: 180
# @tags: usage, image, python, cli, pdf
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src.tiff"
pdf="$tmpdir/out.pdf"

python3 - <<'PY' "$src"
import sys
from PIL import Image

size = (32, 24)
pixels = [
    ((x * 8) % 256, (y * 9) % 256, ((x + y) * 6) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$src"
tiff2pdf -o "$pdf" "$src"
validator_require_file "$pdf"

size=$(stat -c '%s' "$pdf")
[[ $size -gt 200 ]] || {
    printf 'tiff2pdf produced suspiciously small file: %s bytes\n' "$size" >&2
    exit 1
}

python3 - <<'PY' "$pdf"
import sys

with open(sys.argv[1], "rb") as fh:
    head = fh.read(8)
assert head.startswith(b"%PDF-"), head
print("pdf", head[:8])
PY
