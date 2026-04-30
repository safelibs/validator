#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiff2pdf-a4-paper
# @title: Pillow TIFF tiff2pdf -p A4 paper size
# @description: Writes a TIFF with Pillow, converts it to PDF with tiff2pdf -p A4 to set the page size, and verifies the output starts with %PDF- and is non-empty.
# @timeout: 180
# @tags: usage, image, python, cli, pdf
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src.tiff"
pdf="$tmpdir/a4.pdf"

python3 - <<'PY' "$src"
import sys
from PIL import Image

path = sys.argv[1]
size = (40, 28)
pixels = [
    ((x * 8) % 256, (y * 9) % 256, ((x + y) * 6) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path)
PY

validator_require_file "$src"
tiff2pdf -p A4 -o "$pdf" "$src"
validator_require_file "$pdf"

size_bytes=$(stat -c '%s' "$pdf")
[[ $size_bytes -gt 200 ]] || {
    printf 'tiff2pdf A4 produced suspiciously small file: %s bytes\n' "$size_bytes" >&2
    exit 1
}

python3 - <<'PY' "$pdf"
import sys

with open(sys.argv[1], "rb") as fh:
    head = fh.read(8)
assert head.startswith(b"%PDF-"), head
print("pdf-a4", head[:8])
PY
