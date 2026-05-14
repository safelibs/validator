#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r18-img-linked-version-positive
# @title: SDL2_image IMG_Linked_Version reports a non-null SDL_version with positive major
# @description: Compiles a small C program that calls IMG_Linked_Version() and prints the runtime-linked SDL_image version, then asserts the pointer is non-null and the major component is at least 2 — sanity-checking the SDL2_image library load that backs the libwebp decoder path.
# @timeout: 180
# @tags: usage, libsdl2-image, version, r18
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
  if (!v) { fprintf(stderr, "null version pointer\n"); return 1; }
  printf("major=%d minor=%d patch=%d\n", v->major, v->minor, v->patch);
  return 0;
}
C

gcc "$tmpdir/v.c" -o "$tmpdir/v" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/v" >"$tmpdir/out.txt"
grep -Eq '^major=[2-9][0-9]* minor=[0-9]+ patch=[0-9]+$' "$tmpdir/out.txt"
