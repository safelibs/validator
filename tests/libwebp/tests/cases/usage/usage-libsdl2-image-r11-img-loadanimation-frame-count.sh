#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r11-img-loadanimation-frame-count
# @title: SDL2_image IMG_LoadAnimation reports the WebP frame count
# @description: Builds a 3-frame animated WebP via Pillow then loads it through IMG_LoadAnimation, asserting the returned IMG_Animation reports count==3 and matches the source geometry.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, compile, animation
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/anim.webp"
import sys
from PIL import Image
frames = [Image.new('RGB', (10, 10), (50 * i + 10, 100, 150)) for i in range(3)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=120, loop=0)
PY

cat >"$tmpdir/anim.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 1;
  IMG_Animation *a = IMG_LoadAnimation(argv[1]);
  if (!a) { fprintf(stderr, "load failed: %s\n", IMG_GetError()); return 2; }
  printf("frames=%d w=%d h=%d\n", a->count, a->w, a->h);
  int ok = (a->count == 3 && a->w == 10 && a->h == 10);
  IMG_FreeAnimation(a);
  IMG_Quit();
  return ok ? 0 : 3;
}
C

gcc "$tmpdir/anim.c" -o "$tmpdir/anim" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/anim" "$tmpdir/anim.webp"
