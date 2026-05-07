#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r13-webp-img-load-rgb-pixel-format
# @title: SDL2_image IMG_Load on a lossless RGB WebP returns a 24/32-bit surface
# @description: Saves an opaque RGB lossless WebP via Pillow, loads it through IMG_Load, and asserts the surface BitsPerPixel is 24 or 32 (RGB or RGBA), confirming SDL2_image presents the WebP-decoded surface in a normal pixel format.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, compile
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
img = Image.new('RGB', (20, 16), (180, 60, 120))
img.save(sys.argv[1], 'WEBP', lossless=True)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if (argc < 2) return 64;
  SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
  if (SDL_Init(SDL_INIT_VIDEO) != 0) return 1;
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 2;
  SDL_Surface *s = IMG_Load(argv[1]);
  if (!s) { fprintf(stderr, "%s\n", IMG_GetError()); return 3; }
  int bpp = s->format->BitsPerPixel;
  printf("w=%d h=%d bpp=%d\n", s->w, s->h, bpp);
  int ok = (s->w == 20 && s->h == 16 && (bpp == 24 || bpp == 32));
  SDL_FreeSurface(s);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 4;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/in.webp" >"$tmpdir/out.txt"
grep -q 'bpp=24\|bpp=32' "$tmpdir/out.txt"
