#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-webp-load-texture-dim
# @title: SDL2_image IMG_LoadTexture WebP dimensions
# @description: Compiles an SDL2_image client that creates a software renderer and IMG_LoadTexture from a WebP, verifying the texture query reports the expected dimensions.
# @timeout: 180
# @tags: usage, webp, sdl
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

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

cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if (argc < 2) return 10;
  SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
  if (SDL_Init(SDL_INIT_VIDEO) != 0) {
    fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
    return 1;
  }
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) {
    fprintf(stderr, "IMG_Init webp: %s\n", IMG_GetError());
    return 2;
  }
  SDL_Window *win = SDL_CreateWindow("t", 0, 0, 16, 16, SDL_WINDOW_HIDDEN);
  if (!win) { fprintf(stderr, "win: %s\n", SDL_GetError()); return 3; }
  SDL_Renderer *ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
  if (!ren) { fprintf(stderr, "ren: %s\n", SDL_GetError()); return 4; }
  SDL_Texture *tex = IMG_LoadTexture(ren, argv[1]);
  if (!tex) { fprintf(stderr, "tex: %s\n", IMG_GetError()); return 5; }
  int w = -1, h = -1;
  Uint32 fmt = 0;
  int access = -1;
  if (SDL_QueryTexture(tex, &fmt, &access, &w, &h) != 0) {
    fprintf(stderr, "query: %s\n", SDL_GetError());
    return 6;
  }
  printf("texture=%dx%d\n", w, h);
  SDL_DestroyTexture(tex);
  SDL_DestroyRenderer(ren);
  SDL_DestroyWindow(win);
  IMG_Quit();
  SDL_Quit();
  return (w == 4 && h == 3) ? 0 : 7;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/in.webp" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'texture=4x3'
