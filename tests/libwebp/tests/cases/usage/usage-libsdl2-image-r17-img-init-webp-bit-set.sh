#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r17-img-init-webp-bit-set
# @title: SDL2_image IMG_Init(IMG_INIT_WEBP) sets the WEBP flag in its return mask
# @description: Compiles a tiny C program that calls IMG_Init(IMG_INIT_WEBP) and asserts the returned bitmask has the WEBP bit set, confirming the SDL2_image build can dynamically activate WebP support backed by libwebp.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, init
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/v.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(void) {
  int rc = IMG_Init(IMG_INIT_WEBP);
  if ((rc & IMG_INIT_WEBP) == 0) {
    printf("missing IMG_INIT_WEBP bit in 0x%x\n", rc);
    return 1;
  }
  printf("flags=0x%x\n", rc & IMG_INIT_WEBP);
  IMG_Quit();
  return 0;
}
C

gcc "$tmpdir/v.c" -o "$tmpdir/v" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/v" >"$tmpdir/out.txt"
grep -Eq '^flags=0x[0-9a-fA-F]+$' "$tmpdir/out.txt"
