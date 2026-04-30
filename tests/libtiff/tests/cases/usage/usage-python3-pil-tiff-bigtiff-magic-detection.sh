#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-bigtiff-magic-detection
# @title: Pillow TIFF endianness magic detection
# @description: Writes a TIFF with Pillow (little-endian) and a hand-crafted minimal big-endian TIFF, then verifies the II*/MM* magic bytes and that Pillow can detect format on the LE file.
# @timeout: 180
# @tags: usage, image, python, format
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

le_img="$tmpdir/le.tiff"
be_img="$tmpdir/be.tiff"

python3 - <<'PY' "$le_img" "$be_img"
import struct
import sys
from PIL import Image

le_path, be_path = sys.argv[1], sys.argv[2]

# Little-endian TIFF via Pillow.
Image.new("RGB", (4, 3), (12, 34, 56)).save(le_path)
with open(le_path, "rb") as fh:
    magic = fh.read(4)
assert magic == b"II*\x00", magic

# Hand-crafted minimal big-endian classic TIFF: 1x1 grayscale uncompressed.
# IFD at offset 16. 8 entries.
header = b"MM\x00\x2a" + struct.pack(">I", 16)
pixel = b"\xab"
# Place pixel after header.
pixel_offset = 8
ifd_offset = 16
entries = []


def entry(tag, ftype, count, value_bytes):
    if len(value_bytes) > 4:
        raise ValueError("inline only")
    padded = value_bytes + b"\x00" * (4 - len(value_bytes))
    return struct.pack(">HHI", tag, ftype, count) + padded


# 256 ImageWidth SHORT 1 = 1
entries.append(entry(256, 3, 1, struct.pack(">H", 1) + b"\x00\x00"))
# 257 ImageLength SHORT 1 = 1
entries.append(entry(257, 3, 1, struct.pack(">H", 1) + b"\x00\x00"))
# 258 BitsPerSample SHORT 1 = 8
entries.append(entry(258, 3, 1, struct.pack(">H", 8) + b"\x00\x00"))
# 259 Compression SHORT 1 = 1
entries.append(entry(259, 3, 1, struct.pack(">H", 1) + b"\x00\x00"))
# 262 PhotometricInterpretation SHORT 1 = 1 (BlackIsZero)
entries.append(entry(262, 3, 1, struct.pack(">H", 1) + b"\x00\x00"))
# 273 StripOffsets LONG 1 = pixel_offset
entries.append(entry(273, 4, 1, struct.pack(">I", pixel_offset)))
# 277 SamplesPerPixel SHORT 1 = 1
entries.append(entry(277, 3, 1, struct.pack(">H", 1) + b"\x00\x00"))
# 279 StripByteCounts LONG 1 = 1
entries.append(entry(279, 4, 1, struct.pack(">I", 1)))

ifd_count = struct.pack(">H", len(entries))
ifd_body = b"".join(entries)
next_ifd = struct.pack(">I", 0)

with open(be_path, "wb") as fh:
    fh.write(header)
    fh.write(pixel)
    # pad to ifd_offset
    fh.write(b"\x00" * (ifd_offset - (len(header) + len(pixel))))
    fh.write(ifd_count)
    fh.write(ifd_body)
    fh.write(next_ifd)

with open(be_path, "rb") as fh:
    be_magic = fh.read(4)
assert be_magic == b"MM\x00\x2a", be_magic

# Pillow opens the LE file we wrote.
with Image.open(le_path) as im:
    im.load()
    assert im.format == "TIFF", im.format
    assert im.size == (4, 3), im.size

# And opens the hand-crafted big-endian classic TIFF.
with Image.open(be_path) as im:
    im.load()
    assert im.format == "TIFF", im.format
    assert im.size == (1, 1), im.size
    assert im.mode == "L", im.mode

print("magic", magic, be_magic)
PY
