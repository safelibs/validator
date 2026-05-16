#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r21-img-load-webp-pixels-non-null
# @title: SDL2_image IMG_Load on a WEBP yields a surface with a non-null pixels pointer
# @description: Generates a small RGB WEBP via Pillow, calls IMG_Load from a tiny C harness, asserts the returned SDL_Surface has a non-null pixels pointer and positive pitch — pinning SDL2_image's WebP loader path through libwebp on Ubuntu 24.04.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, pixels, surface, r21
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.webp" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (40, 32), (123, 45, 67))
img.save(sys.argv[1], 'WEBP', quality=82)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if (argc < 2) return 64;
  SDL_Surface *s = IMG_Load(argv[1]);
  if (!s) { fprintf(stderr, "IMG_Load failed: %s\n", IMG_GetError()); return 1; }
  printf("pixels_null=%d pitch=%d w=%d h=%d\n",
         (s->pixels == NULL), s->pitch, s->w, s->h);
  SDL_FreeSurface(s);
  return 0;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/in.webp" >"$tmpdir/out.txt"
grep -Eq '^pixels_null=0 pitch=[1-9][0-9]* w=40 h=32$' "$tmpdir/out.txt" || {
    echo "unexpected probe output:" >&2
    cat "$tmpdir/out.txt" >&2
    exit 1
}
