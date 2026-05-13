#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-jpeg-exif-bytes-roundtrip
# @title: Pillow JPEG save exif=bytes round-trips through im.info["exif"]
# @description: Saves an RGB JPEG via Pillow with a hand-built little-endian EXIF block carrying Software="R16PILExif" and re-opens to confirm im.info["exif"] starts with the same MM*/II* header and contains the original Software bytes, exercising libjpeg-turbo's APP1 EXIF segment writer/reader through Pillow.
# @timeout: 60
# @tags: usage, jpeg, python, exif
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

def le16(v): return v.to_bytes(2, "little")
def le32(v): return v.to_bytes(4, "little")

value = b"R16PILExif\x00"  # 11 bytes
header = b"II*\x00" + le32(8)
n_entries = le16(1)
ifd0_size = 2 + 12 + 4
value_offset = 8 + ifd0_size
entry = le16(0x0131) + le16(2) + le32(len(value)) + le32(value_offset)
next_ifd = le32(0)
exif_block = header + n_entries + entry + next_ifd + value

base = Path(sys.argv[1])
out = base / "exif.jpg"
src = Image.new("RGB", (24, 18), (100, 150, 200))
src.save(out, "JPEG", quality=85, exif=exif_block)

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG"
    rt = im.info.get("exif", b"")
    assert rt[:4] in (b"II*\x00", b"MM\x00*"), rt[:4]
    assert b"R16PILExif" in rt, "Software value missing from round-tripped EXIF"
PY
