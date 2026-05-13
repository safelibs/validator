#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-pil-exif-software-readback
# @title: exif --tag Software reads back ValidatorR16PIL written by Pillow EXIF
# @description: Generates a small JPEG with Pillow embedding an EXIF block containing Software=ValidatorR16PIL via exif=bytes, then runs exif --tag=Software --machine-readable and asserts the readback line equals the original string, exercising libexif's ASCII tag reader on a Pillow-produced EXIF segment.
# @timeout: 90
# @tags: usage, pil, software
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/img.jpg" <<'PY'
import sys
from PIL import Image

# Hand-build a minimal little-endian TIFF/EXIF block with one ASCII entry:
# Software (0x0131) = "ValidatorR16PIL\x00"
def le16(v): return v.to_bytes(2, "little")
def le32(v): return v.to_bytes(4, "little")

value = b"ValidatorR16PIL\x00"  # 16 bytes
header = b"II*\x00" + le32(8)       # IFD0 starts at offset 8
n_entries = le16(1)
# Tag=0x0131, type=2 (ASCII), count=len(value)
# value > 4 bytes so value_offset points to bytes after IFD0
ifd0_size = 2 + 12 + 4               # entries count + 1 entry + next-ifd
value_offset = 8 + ifd0_size
entry = le16(0x0131) + le16(2) + le32(len(value)) + le32(value_offset)
next_ifd = le32(0)
exif_block = header + n_entries + entry + next_ifd + value

src = Image.new("RGB", (32, 24), (200, 150, 100))
src.save(sys.argv[1], "JPEG", quality=85, exif=exif_block)
PY

out=$(exif --tag=Software --machine-readable "$tmpdir/img.jpg")
if [[ "$out" != "ValidatorR16PIL" ]]; then
  printf 'expected Software=ValidatorR16PIL, got: %s\n' "$out" >&2
  exit 1
fi
