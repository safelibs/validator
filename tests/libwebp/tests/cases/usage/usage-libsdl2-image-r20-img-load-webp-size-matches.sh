#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r20-img-load-webp-size-matches
# @title: SDL2_image IMG_Load on a WEBP returns a surface whose width and height match the source
# @description: Saves a 72x48 RGB WEBP via Pillow, calls SDL2_image IMG_Load directly on the file path and asserts the returned SDL_Surface reports w=72 and h=48 — pinning the libwebp-backed IMG_Load path's dimension exposure.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, img-load, dimensions, r20
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.webp" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (72, 48), (160, 60, 220))
img.save(sys.argv[1], 'WEBP', quality=85)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if (argc < 2) return 64;
  SDL_Surface *surf = IMG_Load(argv[1]);
  if (!surf) { fprintf(stderr, "IMG_Load failed: %s\n", IMG_GetError()); return 1; }
  printf("w=%d h=%d\n", surf->w, surf->h);
  SDL_FreeSurface(surf);
  return 0;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/in.webp" >"$tmpdir/out.txt"
grep -q '^w=72 h=48$' "$tmpdir/out.txt" || {
    echo "expected w=72 h=48" >&2
    cat "$tmpdir/out.txt" >&2
    exit 1
}
