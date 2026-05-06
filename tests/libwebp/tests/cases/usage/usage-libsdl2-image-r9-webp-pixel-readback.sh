#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r9-webp-pixel-readback
# @title: SDL2_image WebP pixel readback after load
# @description: Encodes a uniform red 4x4 PPM as lossless WebP, loads via SDL2_image into a 32-bit RGBA8888 surface, and asserts the centre pixel reads back as the expected red.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, compile
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 4, 4
px = bytes([200, 30, 40]) * (W * H)
open(sys.argv[1], 'wb').write(b'P6\n4 4\n255\n' + px)
PY

cwebp -lossless -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"

cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>
#include <stdint.h>
int main(int argc, char **argv) {
  SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
  if (SDL_Init(SDL_INIT_VIDEO) != 0) return 1;
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 2;
  SDL_Surface *s = IMG_Load(argv[1]);
  if (!s) return 3;
  SDL_Surface *conv = SDL_ConvertSurfaceFormat(s, SDL_PIXELFORMAT_RGBA8888, 0);
  SDL_FreeSurface(s);
  if (!conv) return 4;
  uint32_t *p = (uint32_t *)conv->pixels;
  uint32_t v = p[2 * (conv->pitch / 4) + 2];
  uint8_t r = (v >> 24) & 0xff;
  uint8_t g = (v >> 16) & 0xff;
  uint8_t b = (v >> 8) & 0xff;
  printf("rgb=%d,%d,%d\n", r, g, b);
  if (!(r > 150 && g < 80 && b < 80)) {
    SDL_FreeSurface(conv); IMG_Quit(); SDL_Quit();
    return 5;
  }
  SDL_FreeSurface(conv);
  IMG_Quit();
  SDL_Quit();
  return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/in.webp"
