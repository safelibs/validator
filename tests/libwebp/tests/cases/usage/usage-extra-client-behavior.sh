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
  usage-python3-pil-lossless-webp)
    python3 - <<'PY' "$tmpdir/lossless.webp"
from PIL import Image
import sys
im = Image.new("RGB", (3, 2), "red")
im.save(sys.argv[1], "WEBP", lossless=True)
with Image.open(sys.argv[1]) as reopened:
    reopened.load(); assert reopened.size == (3, 2); print("lossless", reopened.size)
PY
    ;;
  usage-python3-pil-resize-webp)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.resize((2, 2))
    out.save(sys.argv[2], "WEBP")
with Image.open(sys.argv[2]) as im:
    assert im.size == (2, 2); print("resize", im.size)
PY
    ;;
  usage-python3-pil-thumbnail-webp)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.thumbnail((2, 2))
    assert im.size[0] <= 2 and im.size[1] <= 2
    print("thumbnail", im.size)
PY
    ;;
  usage-vips-webp-crop)
    make_webp
    vips extract_area "$tmpdir/in.webp" "$tmpdir/crop.png" 1 0 2 2
    vipsheader "$tmpdir/crop.png" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2x2'
    ;;
  usage-vips-webp-jpeg-copy)
    make_webp
    vips copy "$tmpdir/in.webp" "$tmpdir/out.jpg"
    file "$tmpdir/out.jpg" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'JPEG image data'
    ;;
  usage-ffmpeg-webp-bmp)
    make_webp
    ffmpeg -hide_banner -loglevel error -i "$tmpdir/in.webp" "$tmpdir/out.bmp"
    file "$tmpdir/out.bmp" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'PC bitmap'
    ;;
  usage-ffmpeg-webp-md5)
    make_webp
    ffmpeg -hide_banner -loglevel error -i "$tmpdir/in.webp" -f md5 - >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'MD5='
    ;;
  usage-webp-pixbuf-loader-info)
    make_webp
    gdk-pixbuf-pixdata "$tmpdir/in.webp" "$tmpdir/out.pixdata"
    validator_require_file "$tmpdir/out.pixdata"
    test "$(wc -c <"$tmpdir/out.pixdata")" -gt 0
    ;;
  usage-libsdl2-image-webp-alpha)
    python3 - <<'PY' "$tmpdir/alpha.ppm"
from pathlib import Path
import sys
Path(sys.argv[1]).write_bytes(b"P6\n2 2\n255\n" + bytes([255,0,0,0,255,0,0,0,255,255,255,0]))
PY
    cwebp -quiet "$tmpdir/alpha.ppm" -o "$tmpdir/alpha.webp"
    cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
  if (SDL_Init(SDL_INIT_VIDEO) != 0) return 1;
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 2;
  SDL_Surface *surface = IMG_Load(argv[1]);
  if (!surface) return 3;
  printf("webp %dx%d\n", surface->w, surface->h);
  int ok = surface->w == 2 && surface->h == 2;
  SDL_FreeSurface(surface);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 4;
}
C
    gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
    "$tmpdir/t" "$tmpdir/alpha.webp"
    ;;
  usage-python3-pil-webp-quality-save)
    make_webp
    python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/quality.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.save(sys.argv[2], "WEBP", quality=50)
with Image.open(sys.argv[2]) as im:
    im.load(); assert im.format == "WEBP"; print("quality", im.size)
PY
    ;;
  *)
    printf 'unknown libwebp extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
