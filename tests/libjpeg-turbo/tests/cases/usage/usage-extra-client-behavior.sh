#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_jpeg() {
  python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY
  cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
}

case "$case_id" in
  usage-python3-pil-crop-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.crop((1, 0, 4, 2))
    out.save(sys.argv[2], "JPEG")
with Image.open(sys.argv[2]) as im:
    assert im.size == (3, 2), im.size
    print("crop", im.size)
PY
    ;;
  usage-python3-pil-rotate-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.transpose(Image.Transpose.ROTATE_90)
    out.save(sys.argv[2], "JPEG")
with Image.open(sys.argv[2]) as im:
    assert im.size == (3, 4), im.size
    print("rotate", im.size)
PY
    ;;
  usage-python3-pil-quality-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.save(sys.argv[2], "JPEG", quality=60)
with Image.open(sys.argv[2]) as im:
    im.load()
    assert im.format == "JPEG"
    print("quality", im.size)
PY
    ;;
  usage-python3-pil-cmyk-jpeg)
    python3 - <<'PY' "$tmpdir/cmyk.jpg"
from PIL import Image
import sys
im = Image.new("CMYK", (3, 2), (0, 128, 128, 0))
im.save(sys.argv[1], "JPEG")
with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    assert reopened.mode == "CMYK", reopened.mode
    print("cmyk", reopened.size, reopened.mode)
PY
    ;;
  usage-python3-pil-exifless-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == "JPEG"
    assert im.size == (4, 3)
    print(im.format, im.size, im.mode)
PY
    ;;
  usage-vips-rotate-jpeg)
    make_jpeg
    vips rot "$tmpdir/in.jpg" "$tmpdir/out.jpg" d90
    vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '3x4'
    ;;
  usage-vips-crop-jpeg)
    make_jpeg
    vips extract_area "$tmpdir/in.jpg" "$tmpdir/crop.jpg" 1 0 2 2
    vipsheader "$tmpdir/crop.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2x2'
    ;;
  usage-vips-jpegsave-quality)
    make_jpeg
    vips copy "$tmpdir/in.jpg" "$tmpdir/quality.jpg[Q=70]"
    file "$tmpdir/quality.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'JPEG image data'
    ;;
  usage-vips-flip-jpeg)
    make_jpeg
    vips flip "$tmpdir/in.jpg" "$tmpdir/flip.jpg" horizontal
    vipsheader "$tmpdir/flip.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4x3'
    ;;
  usage-vips-shrink-jpeg)
    make_jpeg
    vips copy "$tmpdir/in.jpg[shrink=2]" "$tmpdir/shrink.png"
    vipsheader "$tmpdir/shrink.png" | tee "$tmpdir/out"
    grep -Eq '2x2|2x1' "$tmpdir/out"
    ;;
  usage-python3-pil-resize-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.resize((2, 2))
    out.save(sys.argv[2], "JPEG")
with Image.open(sys.argv[2]) as im:
    assert im.size == (2, 2), im.size
    print("resize", im.size)
PY
    ;;
  usage-python3-pil-flip-topbottom-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    out.save(sys.argv[2], "JPEG")
with Image.open(sys.argv[2]) as im:
    assert im.size == (4, 3), im.size
    print("flip", im.size)
PY
    ;;
  usage-python3-pil-jpeg-to-png)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.png"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.save(sys.argv[2], "PNG")
with Image.open(sys.argv[2]) as im:
    assert im.format == "PNG"
    print("png", im.size)
PY
    ;;
  usage-python3-pil-band-split-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    bands = im.split()
    assert len(bands) == 3
    print("bands", len(bands))
PY
    ;;
  usage-python3-pil-optimize-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.save(sys.argv[2], "JPEG", optimize=True)
with Image.open(sys.argv[2]) as im:
    im.load()
    assert im.format == "JPEG"
    print("optimize", im.size)
PY
    ;;
  usage-vips-rot180-jpeg)
    make_jpeg
    vips rot "$tmpdir/in.jpg" "$tmpdir/out.jpg" d180
    vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4x3'
    ;;
  usage-vips-bandmean-jpeg)
    make_jpeg
    vips bandmean "$tmpdir/in.jpg" "$tmpdir/out.png"
    vipsheader "$tmpdir/out.png" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4x3'
    ;;
  usage-vips-linear-jpeg)
    make_jpeg
    vips linear "$tmpdir/in.jpg" "$tmpdir/out.png" 1 10
    vipsheader "$tmpdir/out.png" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4x3'
    ;;
  usage-vips-jpeg-to-tiff)
    make_jpeg
    vips copy "$tmpdir/in.jpg" "$tmpdir/out.tif"
    file "$tmpdir/out.tif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'TIFF image data'
    ;;
  usage-vips-embed-jpeg)
    make_jpeg
    vips embed "$tmpdir/in.jpg" "$tmpdir/embed.png" 1 2 6 7
    vipsheader "$tmpdir/embed.png" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '6x7'
    ;;
  *)
    printf 'unknown libjpeg-turbo extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
