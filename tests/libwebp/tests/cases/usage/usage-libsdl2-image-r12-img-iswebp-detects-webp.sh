#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r12-img-iswebp-detects-webp
# @title: SDL2_image IMG_isWEBP returns true for a real WebP RWops
# @description: Saves a small RGB WebP via Pillow, opens it through SDL_RWFromFile, and asserts IMG_isWEBP(rw) returns 1, confirming the SDL2_image probe is wired into the libwebp-aware build.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, compile
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/sample.webp"
import sys
from PIL import Image
img = Image.new('RGB', (24, 18), (50, 200, 100))
img.save(sys.argv[1], 'WEBP', quality=85)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char **argv) {
  if (argc < 2) return 64;
  SDL_RWops *rw = SDL_RWFromFile(argv[1], "rb");
  if (!rw) { fprintf(stderr, "RWFromFile failed: %s\n", SDL_GetError()); return 1; }
  int v = IMG_isWEBP(rw);
  SDL_RWclose(rw);
  printf("isWEBP=%d\n", v);
  return v == 1 ? 0 : 2;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/sample.webp" >"$tmpdir/out.txt"
grep -q '^isWEBP=1$' "$tmpdir/out.txt"
