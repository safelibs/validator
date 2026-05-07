#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r15-webp-img-load-rw-from-memory-buffer
# @title: SDL2_image IMG_Load_RW from an in-memory WebP buffer returns a non-null surface
# @description: Saves a small RGB WebP via Pillow, loads its bytes into a heap buffer, wraps it with SDL_RWFromMem, and calls IMG_Load_RW(rw, 1, NULL) — asserting the returned SDL_Surface is non-null and reports the original dimensions, exercising the in-memory RWops decode path on a libwebp-decoded image.
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
img = Image.new('RGB', (28, 18), (90, 200, 60))
img.save(sys.argv[1], 'WEBP', quality=85)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char **argv) {
  if (argc < 2) return 64;
  SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
  if (SDL_Init(SDL_INIT_VIDEO) != 0) return 1;
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 2;
  FILE *f = fopen(argv[1], "rb");
  if (!f) return 3;
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  fseek(f, 0, SEEK_SET);
  void *buf = malloc((size_t)n);
  if (!buf || fread(buf, 1, (size_t)n, f) != (size_t)n) return 4;
  fclose(f);
  SDL_RWops *rw = SDL_RWFromMem(buf, (int)n);
  if (!rw) { fprintf(stderr, "%s\n", SDL_GetError()); return 5; }
  SDL_Surface *s = IMG_Load_RW(rw, 1);
  free(buf);
  if (!s) { fprintf(stderr, "%s\n", IMG_GetError()); return 6; }
  printf("w=%d h=%d\n", s->w, s->h);
  int ok = (s->w == 28 && s->h == 18);
  SDL_FreeSurface(s);
  IMG_Quit();
  SDL_Quit();
  return ok ? 0 : 7;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/in.webp" >"$tmpdir/out.txt"
grep -q '^w=28 h=18$' "$tmpdir/out.txt"
