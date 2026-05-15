#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r19-img-savepng-from-loaded-webp
# @title: SDL2_image IMG_SavePNG writes a non-empty PNG from a WEBP-loaded surface
# @description: Generates a WEBP via Pillow, loads it through IMG_Load into an SDL surface, calls IMG_SavePNG to write a PNG copy, and asserts the resulting PNG is non-empty and identified as a PNG image by file(1) — pinning the libwebp-load + libsdl2-image-save chain.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, savepng, r19
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.webp" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (40, 30), (50, 130, 220))
img.save(sys.argv[1], 'WEBP', quality=75)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if (argc < 3) return 64;
  SDL_Surface *surf = IMG_Load(argv[1]);
  if (!surf) { fprintf(stderr, "IMG_Load failed: %s\n", IMG_GetError()); return 1; }
  if (IMG_SavePNG(surf, argv[2]) != 0) { fprintf(stderr, "IMG_SavePNG failed: %s\n", IMG_GetError()); return 1; }
  SDL_FreeSurface(surf);
  return 0;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/in.webp" "$tmpdir/out.png"
test -s "$tmpdir/out.png"
file "$tmpdir/out.png" | grep -qi 'PNG image'
