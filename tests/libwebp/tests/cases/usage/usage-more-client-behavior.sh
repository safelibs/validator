#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_webp() {
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
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

case "$case_id" in
  usage-python3-pil-mirror-webp)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    out.save(sys.argv[2], "WEBP")
with Image.open(sys.argv[2]) as im:
    assert im.size == (4, 3)
    print("mirror", im.size)
PY
    ;;
  usage-python3-pil-memory-open-webp)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp"
from io import BytesIO
from pathlib import Path
from PIL import Image
import sys
payload = Path(sys.argv[1]).read_bytes()
with Image.open(BytesIO(payload)) as im:
    im.load()
    assert im.size == (4, 3)
    print("memory", im.size)
PY
    ;;
  usage-python3-pil-paste-canvas-webp)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    canvas = Image.new("RGB", (6, 5), "black")
    canvas.paste(im, (1, 1))
    canvas.save(sys.argv[2], "WEBP")
with Image.open(sys.argv[2]) as im:
    assert im.size == (6, 5)
    print("paste", im.size)
PY
    ;;
  usage-python3-pil-point-offset-webp)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.point(lambda value: min(255, value + 15))
    out.save(sys.argv[2], "WEBP")
with Image.open(sys.argv[2]) as im:
    assert im.size == (4, 3)
    print("point", im.size)
PY
    ;;
  usage-python3-pil-rotate-270-webp)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.transpose(Image.Transpose.ROTATE_270)
    out.save(sys.argv[2], "WEBP")
with Image.open(sys.argv[2]) as im:
    assert im.size == (3, 4)
    print("rotate270", im.size)
PY
    ;;
  usage-vips-rot180-webp)
    make_webp
    vips rot "$tmpdir/in.webp" "$tmpdir/out.png" d180
    vipsheader "$tmpdir/out.png" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4x3'
    ;;
  usage-vips-flip-vertical-webp)
    make_webp
    vips flip "$tmpdir/in.webp" "$tmpdir/out.png" vertical
    vipsheader "$tmpdir/out.png" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4x3'
    ;;
  usage-vips-embed-webp)
    make_webp
    vips embed "$tmpdir/in.webp" "$tmpdir/out.png" 1 2 6 7
    vipsheader "$tmpdir/out.png" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '6x7'
    ;;
  usage-ffmpeg-webp-jpeg)
    make_webp
    ffmpeg -hide_banner -loglevel error -i "$tmpdir/in.webp" "$tmpdir/out.jpg"
    file "$tmpdir/out.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'JPEG image data'
    ;;
  usage-ffprobe-webp-dimensions)
    make_webp
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of default=noprint_wrappers=1 "$tmpdir/in.webp" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'width=4'
    validator_assert_contains "$tmpdir/out" 'height=3'
    ;;
  *)
    printf 'unknown libwebp additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
