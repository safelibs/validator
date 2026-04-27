#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_ppm() {
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
}

make_webp() {
  make_ppm
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

case "$case_id" in
  usage-python3-pil-webp-getbbox)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    bbox = im.getbbox()
    assert bbox is not None
    assert bbox[2] - bbox[0] <= im.size[0]
    assert bbox[3] - bbox[1] <= im.size[1]
    print("bbox", bbox)
PY
    ;;
  usage-python3-pil-webp-tobytes-length)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    data = im.convert("RGB").tobytes()
    assert len(data) == im.size[0] * im.size[1] * 3
    print("bytes", len(data))
PY
    ;;
  usage-python3-pil-webp-histogram-length)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    hist = im.convert("RGB").histogram()
    assert len(hist) == 768
    assert sum(hist) == im.size[0] * im.size[1] * 3
    print("hist", len(hist), sum(hist))
PY
    ;;
  usage-python3-pil-webp-split-bands)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    bands = im.convert("RGB").split()
    assert len(bands) == 3
    for band in bands:
        assert band.mode == "L"
        assert band.size == im.size
    print("bands", len(bands))
PY
    ;;
  usage-python3-pil-webp-paste-corner)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    rgb = im.convert("RGB")
    canvas = Image.new("RGB", (rgb.size[0] * 2, rgb.size[1]), (0, 0, 0))
    canvas.paste(rgb, (rgb.size[0], 0))
    canvas.save(sys.argv[2], "WEBP", lossless=True)
with Image.open(sys.argv[2]) as out:
    out.load()
    assert out.size == (rgb.size[0] * 2, rgb.size[1])
    assert out.getpixel((0, 0)) == (0, 0, 0)
    print("paste", out.size)
PY
    ;;
  usage-python3-pil-webp-grayscale-mode)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/gray.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    gray = im.convert("L").convert("RGB")
    gray.save(sys.argv[2], "WEBP", lossless=True)
with Image.open(sys.argv[2]) as reopened:
    reopened.load()
    pixel = reopened.getpixel((0, 0))
    assert pixel[0] == pixel[1] == pixel[2]
    print("gray", pixel)
PY
    ;;
  usage-vips-webp-extract-area-header)
    make_webp
    vips extract_area "$tmpdir/in.webp" "$tmpdir/area.png" 0 0 3 2
    vipsheader "$tmpdir/area.png" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '3x2'
    ;;
  usage-vips-webp-embed-canvas)
    make_webp
    vips embed "$tmpdir/in.webp" "$tmpdir/embed.png" 1 1 8 6
    vipsheader "$tmpdir/embed.png" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '8x6'
    ;;
  usage-ffmpeg-webp-pgm-output)
    make_webp
    ffmpeg -hide_banner -loglevel error -i "$tmpdir/in.webp" -pix_fmt gray "$tmpdir/out.pgm"
    head -c 2 "$tmpdir/out.pgm" >"$tmpdir/magic"
    validator_assert_contains "$tmpdir/magic" 'P5'
    ;;
  usage-ffmpeg-webp-tiff-output)
    make_webp
    ffmpeg -hide_banner -loglevel error -i "$tmpdir/in.webp" "$tmpdir/out.tiff"
    file "$tmpdir/out.tiff" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'TIFF image data'
    ;;
  *)
    printf 'unknown libwebp tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
