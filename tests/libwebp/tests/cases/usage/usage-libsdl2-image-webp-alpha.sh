#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-webp-alpha
# @title: SDL2_image WebP alpha
# @description: Compiles an SDL2_image client that loads alpha WebP data and checks dimensions.
# @timeout: 180
# @tags: usage, webp, sdl
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libsdl2-image-webp-alpha"
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

python3 - <<'PY' "$tmpdir/alpha.ppm"
from pathlib import Path
import sys
Path(sys.argv[1]).write_bytes(b"P6\n2 2\n255\n" + bytes([255,0,0,0,255,0,0,0,255,255,255,0]))
PY
cwebp -quiet "$tmpdir/alpha.ppm" -o "$tmpdir/alpha.webp"
cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
  if (SDL_Init(SDL_INIT_VIDEO) != 0) return 1;
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 2;
  SDL_Surface *surface = IMG_Load(argv[1]);
  if (!surface) return 3;
  printf("webp %dx%d\n", surface->w, surface->h);
  int ok = surface->w == 2 && surface->h == 2;
  SDL_FreeSurface(surface);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 4;
}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/alpha.webp"
