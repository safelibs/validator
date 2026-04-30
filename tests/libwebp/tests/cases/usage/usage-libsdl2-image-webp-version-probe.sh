#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-webp-version-probe
# @title: SDL2_image WEBP version probe
# @description: Compiles an SDL2_image client that calls IMG_Linked_Version, asserts the linked version is non-NULL with major==2, initialises IMG_INIT_WEBP, and confirms a WebP fixture loads through the same library.
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
  const SDL_version *v = IMG_Linked_Version();
  if (!v) return 1;
  if (v->major != 2) {
    fprintf(stderr, "unexpected major: %d\n", v->major);
    return 2;
  }
  SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
  if (SDL_Init(SDL_INIT_VIDEO) != 0) return 3;
  int got = IMG_Init(IMG_INIT_WEBP);
  if ((got & IMG_INIT_WEBP) == 0) {
    fprintf(stderr, "IMG_Init returned 0x%x\n", got);
    SDL_Quit();
    return 4;
  }
  SDL_Surface *surface = IMG_Load(argv[1]);
  if (!surface) {
    fprintf(stderr, "IMG_Load failed: %s\n", IMG_GetError());
    IMG_Quit();
    SDL_Quit();
    return 5;
  }
  printf("major=%d minor=%d patch=%d size=%dx%d\n",
         v->major, v->minor, v->patch, surface->w, surface->h);
  int ok = surface->w == 4 && surface->h == 3;
  SDL_FreeSurface(surface);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 6;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/in.webp" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'major=2'
validator_assert_contains "$tmpdir/out" 'size=4x3'
