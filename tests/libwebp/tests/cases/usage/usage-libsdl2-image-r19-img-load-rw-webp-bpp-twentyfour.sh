#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r19-img-load-rw-webp-bpp-twentyfour
# @title: SDL2_image IMG_Load_RW on RGB WEBP returns a surface with BytesPerPixel of 3 or 4
# @description: Generates an RGB WEBP via Pillow, opens it through SDL_RWFromFile, calls IMG_Load_RW with freesrc=1, and asserts the surface format BytesPerPixel value is 3 (RGB24) or 4 (RGBA32) — pinning the libwebp-backed IMG_Load_RW path.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, rwops, r19
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.webp" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (60, 40), (90, 30, 200))
img.save(sys.argv[1], 'WEBP', quality=80)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if (argc < 2) return 64;
  SDL_RWops *rw = SDL_RWFromFile(argv[1], "rb");
  if (!rw) { fprintf(stderr, "RWFromFile failed: %s\n", SDL_GetError()); return 1; }
  SDL_Surface *surf = IMG_Load_RW(rw, 1);
  if (!surf) { fprintf(stderr, "IMG_Load_RW failed: %s\n", IMG_GetError()); return 1; }
  printf("bpp=%d\n", surf->format->BytesPerPixel);
  SDL_FreeSurface(surf);
  return 0;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/in.webp" >"$tmpdir/out.txt"
grep -Eq '^bpp=(3|4)$' "$tmpdir/out.txt" || {
    echo "expected bpp 3 or 4" >&2
    cat "$tmpdir/out.txt" >&2
    exit 1
}
