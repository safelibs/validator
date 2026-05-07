#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r14-webp-img-load-pitch-positive
# @title: SDL2_image IMG_Load on a WebP returns a surface with pitch >= width * BytesPerPixel
# @description: Saves a small RGB WebP via Pillow, loads it via IMG_Load, and asserts the SDL_Surface pitch is >= width*BytesPerPixel (the row-stride lower bound), exercising the surface-stride invariant after a libwebp decode.
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
img = Image.new('RGB', (20, 14), (60, 200, 120))
img.save(sys.argv[1], 'WEBP', quality=85)
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
  int bpp = s->format->BytesPerPixel;
  int pitch = s->pitch;
  int min_pitch = s->w * bpp;
  printf("w=%d h=%d bpp_bytes=%d pitch=%d\n", s->w, s->h, bpp, pitch);
  int ok = (pitch >= min_pitch && bpp >= 3);
  SDL_FreeSurface(s);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 4;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/in.webp" >"$tmpdir/out.txt"
grep -q '^w=20 h=14 ' "$tmpdir/out.txt"
