#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-webp-load-rw-size
# @title: SDL2_image IMG_LoadWEBP_RW size check
# @description: Compiles a minimal SDL2_image client that opens a WebP fixture via SDL_RWFromFile, decodes it through IMG_LoadWEBP_RW directly (bypassing the format-detection dispatch), prints the SDL_Surface dimensions, and asserts the surface is non-NULL with the expected 4x3 size.
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
  if (SDL_Init(SDL_INIT_VIDEO) != 0) return 1;
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) {
    fprintf(stderr, "IMG_Init WEBP failed: %s\n", IMG_GetError());
    SDL_Quit();
    return 2;
  }
  SDL_RWops *rw = SDL_RWFromFile(argv[1], "rb");
  if (!rw) {
    fprintf(stderr, "SDL_RWFromFile failed: %s\n", SDL_GetError());
    IMG_Quit();
    SDL_Quit();
    return 3;
  }
  SDL_Surface *surface = IMG_LoadWEBP_RW(rw);
  SDL_RWclose(rw);
  if (!surface) {
    fprintf(stderr, "IMG_LoadWEBP_RW failed: %s\n", IMG_GetError());
    IMG_Quit();
    SDL_Quit();
    return 4;
  }
  printf("loadwebp_rw size=%dx%d\n", surface->w, surface->h);
  int ok = surface->w == 4 && surface->h == 3;
  SDL_FreeSurface(surface);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 5;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/in.webp" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'loadwebp_rw size=4x3'
