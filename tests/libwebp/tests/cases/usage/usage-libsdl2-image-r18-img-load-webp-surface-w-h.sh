#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r18-img-load-webp-surface-w-h
# @title: SDL2_image IMG_Load on a Pillow-generated WEBP returns a surface with expected width/height
# @description: Generates a 48x36 WEBP via Pillow, loads it through SDL2_image's IMG_Load, and asserts the resulting SDL_Surface reports width=48 and height=36 before freeing it — exercising the libwebp-backed decoder path in SDL2_image.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, load, r18
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/sample.webp" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (48, 36), (40, 90, 160))
for y in range(36):
    for x in range(48):
        img.putpixel((x, y), ((x * 5) & 0xff, (y * 7) & 0xff, ((x + y) * 3) & 0xff))
img.save(sys.argv[1], 'WEBP', quality=80)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if (argc < 2) return 64;
  SDL_Surface *surf = IMG_Load(argv[1]);
  if (!surf) {
    fprintf(stderr, "IMG_Load failed: %s\n", IMG_GetError());
    return 1;
  }
  printf("w=%d h=%d\n", surf->w, surf->h);
  SDL_FreeSurface(surf);
  return 0;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/sample.webp" >"$tmpdir/out.txt"
grep -q '^w=48 h=36$' "$tmpdir/out.txt"
