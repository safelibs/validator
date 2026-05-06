#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r10-webp-load-typed-rw
# @title: SDL2_image IMG_LoadTyped_RW with explicit WEBP type
# @description: Encodes a small WebP and loads it via IMG_LoadTyped_RW("WEBP") rather than IMG_Load to verify the typed-loader path resolves the WebP decoder.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, compile
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 6, 5
px = bytes([10, 200, 90]) * (W * H)
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + px)
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
  SDL_RWops *rw = SDL_RWFromFile(argv[1], "rb");
  if (!rw) return 3;
  SDL_Surface *s = IMG_LoadTyped_RW(rw, 1, "WEBP");
  if (!s) { fprintf(stderr, "%s\n", IMG_GetError()); return 4; }
  printf("typed-rw %dx%d\n", s->w, s->h);
  int ok = (s->w == 6 && s->h == 5);
  SDL_FreeSurface(s);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 5;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/in.webp"
