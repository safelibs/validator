#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-webp-rwops
# @title: SDL2_image WebP RWops
# @description: Compiles an SDL2_image client that loads WebP data from SDL_RWops memory and checks dimensions.
# @timeout: 180
# @tags: usage, webp, sdl
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libsdl2-image-webp-rwops"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_webp() {
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
}

make_webp
cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char **argv) {
  FILE *fp = fopen(argv[1], "rb");
  if (!fp) return 1;
  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  rewind(fp);
  unsigned char *data = malloc((size_t) size);
  if (!data) return 2;
  if (fread(data, 1, (size_t) size, fp) != (size_t) size) return 3;
  fclose(fp);
  SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
  if (SDL_Init(SDL_INIT_VIDEO) != 0) return 4;
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 5;
  SDL_RWops *rw = SDL_RWFromConstMem(data, (int) size);
  if (!rw) return 6;
  SDL_Surface *surface = IMG_Load_RW(rw, 1);
  if (!surface) return 7;
  printf("webp-rwops %dx%d\n", surface->w, surface->h);
  int ok = surface->w == 4 && surface->h == 3;
  SDL_FreeSurface(surface);
  IMG_Quit();
  SDL_Quit();
  free(data);
  return ok ? 0 : 8;
}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/in.webp"
