#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r11-img-linked-version-major-two
# @title: SDL2_image IMG_Linked_Version reports the SDL2 major version
# @description: Compiles a tiny C program that calls IMG_Linked_Version() and asserts the runtime-reported SDL_image major matches the SDL2 ABI (2.x), proving the WebP-aware build is loaded.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, compile
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/v.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(void) {
  const SDL_version *v = IMG_Linked_Version();
  printf("SDL_image %d.%d.%d\n", v->major, v->minor, v->patch);
  if (v->major != 2) return 1;
  if ((IMG_Init(IMG_INIT_WEBP) & IMG_INIT_WEBP) == 0) return 2;
  IMG_Quit();
  return 0;
}
C

gcc "$tmpdir/v.c" -o "$tmpdir/v" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/v" >"$tmpdir/out.txt"
grep -Eq '^SDL_image 2\.[0-9]+\.[0-9]+$' "$tmpdir/out.txt"
