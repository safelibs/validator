#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-webp-detect
# @title: SDL2_image IMG_isWEBP detection
# @description: Compiles an SDL2_image client that opens a WebP fixture as an SDL_RWops, asserts IMG_isWEBP returns nonzero, then loads the surface via IMG_LoadWEBP_RW and confirms reported dimensions match.
# @timeout: 180
# @tags: usage, webp, sdl, detect
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
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 2;
  SDL_RWops *rw = SDL_RWFromFile(argv[1], "rb");
  if (!rw) return 3;
  int is_webp = IMG_isWEBP(rw);
  if (!is_webp) {
    fprintf(stderr, "IMG_isWEBP returned 0\n");
    SDL_RWclose(rw);
    return 4;
  }
  SDL_RWseek(rw, 0, RW_SEEK_SET);
  SDL_Surface *s = IMG_LoadWEBP_RW(rw);
  SDL_RWclose(rw);
  if (!s) {
    fprintf(stderr, "IMG_LoadWEBP_RW failed: %s\n", IMG_GetError());
    return 5;
  }
  printf("isWEBP=%d size=%dx%d\n", is_webp, s->w, s->h);
  int ok = s->w == 4 && s->h == 3;
  SDL_FreeSurface(s);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 6;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/in.webp" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'isWEBP=1'
validator_assert_contains "$tmpdir/out" 'size=4x3'
