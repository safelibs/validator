#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-pil-artist-tag-readback
# @title: exif --tag Artist reads back the ASCII value written via Pillow EXIF
# @description: Builds a minimal little-endian EXIF block with the Artist (0x013B) ASCII tag set to "R16ArtistName" embedded in a Pillow-saved JPEG, then asserts exif --tag=Artist --machine-readable returns exactly that string, exercising libexif's ASCII reader for the Artist tag.
# @timeout: 90
# @tags: usage, pil, artist
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/img.jpg" <<'PY'
import sys
from PIL import Image

def le16(v): return v.to_bytes(2, "little")
def le32(v): return v.to_bytes(4, "little")

value = b"R16ArtistName\x00"  # 14 bytes ASCII + NUL
header = b"II*\x00" + le32(8)
n_entries = le16(1)
ifd0_size = 2 + 12 + 4
value_offset = 8 + ifd0_size
entry = le16(0x013B) + le16(2) + le32(len(value)) + le32(value_offset)
next_ifd = le32(0)
exif_block = header + n_entries + entry + next_ifd + value

src = Image.new("RGB", (20, 20), (10, 20, 30))
src.save(sys.argv[1], "JPEG", quality=80, exif=exif_block)
PY

out=$(exif --tag=Artist --machine-readable "$tmpdir/img.jpg")
if [[ "$out" != "R16ArtistName" ]]; then
  printf 'expected Artist=R16ArtistName, got: %s\n' "$out" >&2
  exit 1
fi
