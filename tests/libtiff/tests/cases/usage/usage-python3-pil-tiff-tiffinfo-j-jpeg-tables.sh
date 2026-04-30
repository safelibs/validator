#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffinfo-j-jpeg-tables
# @title: Pillow TIFF tiffinfo -j JPEG tables on JPEG-compressed TIFF
# @description: Writes a JPEG-compressed RGB TIFF with Pillow (compression="jpeg"), runs tiffinfo -j to dump the JPEGTables (tag 347) header, and verifies the report mentions Compression Scheme: JPEG and a non-zero JPEG Tables byte count, and that Pillow exposes Compression=7 plus a non-empty JPEGTables tag.
# @timeout: 180
# @tags: usage, image, python, compression, jpeg, cli
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/jpeg.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image

path = sys.argv[1]
size = (32, 24)
pixels = [
    ((x * 7) % 256, (y * 11 + 30) % 256, ((x + y) * 5) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(path, compression="jpeg")
PY

validator_require_file "$img"

report="$tmpdir/info-j.txt"
tiffinfo -j "$img" >"$report"
validator_assert_contains "$report" "Compression Scheme: JPEG"
validator_assert_contains "$report" "JPEG Tables:"
# A JPEG-compressed RGB TIFF must carry a non-empty JPEGTables blob.
if grep -Eq 'JPEG Tables: \(0 bytes\)' "$report"; then
    printf 'JPEG Tables byte count is zero, expected non-zero\n' >&2
    sed -n '1,40p' "$report" >&2
    exit 1
fi

python3 - <<'PY' "$img"
import sys
from PIL import Image

with Image.open(sys.argv[1]) as im:
    im.load()
    comp = im.tag_v2.get(259)
    assert comp == 7, ("compression", comp)
    tables = im.tag_v2.get(347)
    assert tables is not None, "JPEGTables (347) missing"
    if isinstance(tables, tuple):
        tables = bytes(tables)
    assert len(tables) > 0, ("jpeg tables empty", len(tables))
    assert im.size == (32, 24), im.size
    assert im.mode in ("RGB", "YCbCr"), im.mode
    print("jpeg-tables", comp, len(tables), im.mode)
PY
