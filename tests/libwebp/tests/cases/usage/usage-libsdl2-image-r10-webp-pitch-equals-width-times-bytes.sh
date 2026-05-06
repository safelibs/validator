#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r10-webp-pitch-equals-width-times-bytes
# @title: SDL2_image WebP loaded surface pitch equals width * bytes-per-pixel
# @description: Loads a 16x16 lossless WebP via SDL2_image, converts to a known RGBA8888 format, and asserts surface->pitch equals width * 4 with no row padding inserted.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, compile
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 16, 16
data = bytearray()
for y in range(H):
    for x in range(W):
        data += bytes(((x * 16) & 0xff, (y * 16) & 0xff, ((x + y) * 8) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + bytes(data))
PY

cwebp -lossless -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"

cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
  if (SDL_Init(SDL_INIT_VIDEO) != 0) return 1;
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 2;
  SDL_Surface *s = IMG_Load(argv[1]);
  if (!s) return 3;
  SDL_Surface *conv = SDL_ConvertSurfaceFormat(s, SDL_PIXELFORMAT_RGBA8888, 0);
  SDL_FreeSurface(s);
  if (!conv) return 4;
  printf("w=%d h=%d pitch=%d\n", conv->w, conv->h, conv->pitch);
  int ok = (conv->w == 16 && conv->h == 16 && conv->pitch == 16 * 4);
  SDL_FreeSurface(conv);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 5;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/in.webp"
