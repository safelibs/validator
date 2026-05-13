#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-pil-datetime-iso-shape
# @title: exif --tag DateTime returns a 19-character "YYYY:MM:DD HH:MM:SS" shape
# @description: Embeds DateTime (0x0132) = "2026:05:13 12:00:00" via a hand-built EXIF block in a Pillow-saved JPEG and asserts exif --tag=DateTime --machine-readable returns a 19-character string matching the EXIF date-time shape, exercising the libexif ASCII DateTime reader.
# @timeout: 90
# @tags: usage, pil, datetime
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

value = b"2026:05:13 12:00:00\x00"  # 20 bytes incl NUL
header = b"II*\x00" + le32(8)
n_entries = le16(1)
ifd0_size = 2 + 12 + 4
value_offset = 8 + ifd0_size
entry = le16(0x0132) + le16(2) + le32(len(value)) + le32(value_offset)
next_ifd = le32(0)
exif_block = header + n_entries + entry + next_ifd + value

src = Image.new("RGB", (16, 16), (40, 60, 80))
src.save(sys.argv[1], "JPEG", quality=80, exif=exif_block)
PY

out=$(exif --tag=DateTime --machine-readable "$tmpdir/img.jpg")
if [[ ! "$out" =~ ^[0-9]{4}:[0-9]{2}:[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
  printf 'expected EXIF DateTime shape, got: %s\n' "$out" >&2
  exit 1
fi
[[ ${#out} -eq 19 ]] || {
  printf 'expected length 19, got %d\n' "${#out}" >&2
  exit 1
}
