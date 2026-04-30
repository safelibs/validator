#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-jpeg-quality-save
# @title: Pillow TIFF JPEG quality parameter
# @description: Writes a JPEG-compressed TIFF with Pillow using the quality parameter and verifies the Compression tag is 7, the file is non-empty, and the reopened image preserves dimensions and mode.
# @timeout: 180
# @tags: usage, image, python, compression, jpeg
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out="$tmpdir/jpegq.tiff"

python3 - <<'PY' "$out"
import sys
from PIL import Image

path = sys.argv[1]
size = (48, 32)
pixels = [
    ((x * 5) % 256, (y * 7 + 30) % 256, ((x + y) * 11) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
# Quality is honored by Pillow's JPEG-in-TIFF encoder.
image.save(path, compression="jpeg", quality=40)

with Image.open(path) as reopened:
    reopened.load()
    comp = reopened.tag_v2.get(259)
    info = reopened.info.get("compression")
    assert comp == 7, ("compression", comp)
    assert info == "jpeg", ("info compression", info)
    assert reopened.size == size, reopened.size
    assert reopened.mode in ("RGB", "YCbCr"), reopened.mode
    print("jpeg-q40", comp, reopened.size, reopened.mode)
PY

validator_require_file "$out"
size_bytes=$(stat -c '%s' "$out")
[[ $size_bytes -gt 100 ]] || {
    printf 'jpeg-q40 TIFF unexpectedly small: %s bytes\n' "$size_bytes" >&2
    exit 1
}
