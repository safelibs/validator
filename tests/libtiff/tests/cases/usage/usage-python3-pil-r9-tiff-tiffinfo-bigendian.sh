#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-tiffinfo-bigendian
# @title: tiffinfo parses a hand-rolled big-endian TIFF
# @description: Builds a big-endian TIFF via raw struct serialization and verifies tiffinfo can parse it and report the expected ImageWidth/ImageLength dimensions.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/be.tiff" <<'PY'
import sys
from PIL import Image, TiffImagePlugin
img = Image.new("L", (4, 4), 200)
img.encoderinfo = {}
img.save(sys.argv[1], "TIFF")
# Re-encode as big-endian by re-saving via TiffImagePlugin with explicit byte order.
# Use Pillow's tiff writer at low level: write through PIL.TiffImagePlugin's Endian flag.
with open(sys.argv[1], "rb") as f:
    head = f.read(2)
# Pillow defaults to little-endian "II"; convert to big-endian by flipping byte order
# using tifffile-style manual approach: re-save through PIL with `tiffinfo` not enough.
# Instead, build a big-endian file via manual struct serialization.
import struct
w, h = 4, 4
pixels = bytes([200] * (w * h))
with open(sys.argv[1], "wb") as out:
    # Big-endian magic.
    out.write(b"MM")
    out.write(struct.pack(">H", 42))
    out.write(struct.pack(">I", 8))   # IFD offset
    # Tags: ImageWidth (256, SHORT), ImageLength (257, SHORT), BitsPerSample (258, SHORT),
    # Compression (259 = 1), PhotometricInterpretation (262 = 1, blackiszero),
    # StripOffsets (273), RowsPerStrip (278), StripByteCounts (279), SamplesPerPixel (277).
    pixels_offset_placeholder = 0
    tags = []
    def tag_short(tagid, value):
        return struct.pack(">HHI", tagid, 3, 1) + struct.pack(">HH", value, 0)
    def tag_long(tagid, value):
        return struct.pack(">HHI", tagid, 4, 1) + struct.pack(">I", value)
    num_tags = 9
    ifd_size = 2 + num_tags * 12 + 4
    pixels_offset = 8 + ifd_size
    out.write(struct.pack(">H", num_tags))
    out.write(tag_short(256, w))
    out.write(tag_short(257, h))
    out.write(tag_short(258, 8))
    out.write(tag_short(259, 1))
    out.write(tag_short(262, 1))
    out.write(tag_short(277, 1))
    out.write(tag_long(273, pixels_offset))
    out.write(tag_short(278, h))
    out.write(tag_long(279, len(pixels)))
    out.write(struct.pack(">I", 0))   # Next IFD = 0
    out.write(pixels)

with open(sys.argv[1], "rb") as f:
    head = f.read(4)
assert head[:2] == b"MM", head
assert head[2:4] == b"\x00\x2a", head

# Pillow should also accept it.
with Image.open(sys.argv[1]) as ro:
    ro.load()
    assert ro.size == (w, h)
PY

tiffinfo "$tmpdir/be.tiff" >"$tmpdir/info.txt" 2>"$tmpdir/info.err"
validator_assert_contains "$tmpdir/info.txt" 'Image Width: 4'
validator_assert_contains "$tmpdir/info.txt" 'Image Length: 4'
