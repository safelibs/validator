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
  usage-python3-pil-mirror-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    out.save(sys.argv[2], "JPEG")
with Image.open(sys.argv[2]) as im:
    assert im.size == (4, 3)
    print("mirror", im.size)
PY
    ;;
  usage-python3-pil-memory-open-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg"
from io import BytesIO
from pathlib import Path
from PIL import Image
import sys
payload = Path(sys.argv[1]).read_bytes()
with Image.open(BytesIO(payload)) as im:
    assert im.size == (4, 3)
    print("memory", im.size)
PY
    ;;
  usage-python3-pil-paste-canvas-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    canvas = Image.new("RGB", (6, 5), "black")
    canvas.paste(im, (1, 1))
    canvas.save(sys.argv[2], "JPEG")
with Image.open(sys.argv[2]) as im:
    assert im.size == (6, 5)
    print("paste", im.size)
PY
    ;;
  usage-python3-pil-point-offset-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.point(lambda value: min(255, value + 10))
    out.save(sys.argv[2], "JPEG")
with Image.open(sys.argv[2]) as im:
    assert im.size == (4, 3)
    print("point", im.size)
PY
    ;;
  usage-python3-pil-rotate-270-jpeg)
    make_jpeg
    python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.transpose(Image.Transpose.ROTATE_270)
    out.save(sys.argv[2], "JPEG")
with Image.open(sys.argv[2]) as im:
    assert im.size == (3, 4)
    print("rotate270", im.size)
PY
    ;;
  usage-vips-rot270-jpeg)
    make_jpeg
    vips rot "$tmpdir/in.jpg" "$tmpdir/out.jpg" d270
    vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '3x4'
    ;;
  usage-vips-flip-vertical-jpeg)
    make_jpeg
    vips flip "$tmpdir/in.jpg" "$tmpdir/out.jpg" vertical
    vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4x3'
    ;;
  usage-vips-extract-strip-jpeg)
    make_jpeg
    vips extract_area "$tmpdir/in.jpg" "$tmpdir/out.jpg" 0 1 4 1
    vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4x1'
    ;;
  usage-vips-resize-double-jpeg)
    make_jpeg
    vips resize "$tmpdir/in.jpg" "$tmpdir/out.jpg" 2
    vipsheader "$tmpdir/out.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '8x6'
    ;;
  usage-vips-copy-ppm-jpeg)
    make_jpeg
    vips copy "$tmpdir/in.jpg" "$tmpdir/out.ppm"
    file "$tmpdir/out.ppm" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Netpbm image data'
    ;;
  *)
    printf 'unknown libjpeg-turbo additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
