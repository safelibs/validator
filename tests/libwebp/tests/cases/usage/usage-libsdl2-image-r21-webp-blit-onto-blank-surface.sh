#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r21-webp-blit-onto-blank-surface
# @title: SDL2_image WEBP-loaded surface blits successfully onto a blank target surface
# @description: Loads a WEBP via IMG_Load, allocates an RGBA target surface with SDL_CreateRGBSurface, blits the WEBP surface onto it via SDL_BlitSurface and asserts the call succeeds (return 0) — pinning SDL2_image+libwebp+SDL_BlitSurface interop on Ubuntu 24.04.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, blit, surface, r21
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.webp" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (24, 24), (200, 100, 50))
img.save(sys.argv[1], 'WEBP', quality=70)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if (argc < 2) return 64;
  SDL_Surface *src = IMG_Load(argv[1]);
  if (!src) { fprintf(stderr, "IMG_Load: %s\n", IMG_GetError()); return 1; }
  SDL_Surface *dst = SDL_CreateRGBSurface(0, 64, 64, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
  if (!dst) { fprintf(stderr, "CreateRGBSurface: %s\n", SDL_GetError()); return 1; }
  int r = SDL_BlitSurface(src, NULL, dst, NULL);
  printf("blit_rc=%d\n", r);
  SDL_FreeSurface(src);
  SDL_FreeSurface(dst);
  return 0;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/in.webp" >"$tmpdir/out.txt"
grep -q '^blit_rc=0$' "$tmpdir/out.txt" || {
    echo "expected blit_rc=0" >&2
    cat "$tmpdir/out.txt" >&2
    exit 1
}
