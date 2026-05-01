#!/usr/bin/env bash
# @testcase: usage-vips-jpegsave-keep-none-strip
# @title: vips jpegsave --keep none strips metadata
# @description: Resaves a JPEG that carries an Exif APP1 block via vips jpegsave --keep none and verifies the Exif marker is gone in the output, while a default save retains it.
# @timeout: 180
# @tags: usage, jpeg, image, metadata
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
W, H = 32, 24
pixels = bytearray()
for y in range(H):
    for x in range(W):
        pixels += bytes((((x * 9) ^ (y * 5)) & 255, (x * 4) & 255, (y * 4) & 255))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + bytes(pixels))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/raw.jpg"
# Use Pillow to embed an Exif APP1 block so vips has metadata to strip.
python3 - <<'PY' "$tmpdir/raw.jpg" "$tmpdir/in.jpg"
import sys
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
with Image.open(src) as im:
    exif = im.getexif()
    exif[0x010E] = 'safelibs strip test'
    im.save(out, 'JPEG', quality=85, exif=exif.tobytes())
PY

assert_has() { grep -Fq "$2" "$1" || { printf 'expected %s in %s\n' "$2" "$1" >&2; exit 1; }; }

# Default vips jpegsave retains Exif.
vips jpegsave "$tmpdir/in.jpg" "$tmpdir/keep.jpg" --Q 80
# --keep none drops it.
vips jpegsave "$tmpdir/in.jpg" "$tmpdir/strip.jpg" --Q 80 --keep none

python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/keep.jpg" "$tmpdir/strip.jpg"
import sys
from pathlib import Path
src, kept, stripped = (Path(p).read_bytes() for p in sys.argv[1:4])
assert b'Exif\x00\x00' in src[:512], 'fixture missing Exif APP1 — test setup wrong'
assert b'Exif\x00\x00' in kept[:512], 'default jpegsave should preserve Exif'
assert b'Exif\x00\x00' not in stripped, 'jpegsave --keep none did not strip Exif'
assert stripped[:2] == b'\xff\xd8' and stripped[-2:] == b'\xff\xd9', 'stripped JPEG malformed'
print('keep ok exif kept; strip ok exif removed; sizes', len(kept), len(stripped))
PY
