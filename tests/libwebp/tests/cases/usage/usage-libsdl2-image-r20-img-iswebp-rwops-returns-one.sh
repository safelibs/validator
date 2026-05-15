#!/usr/bin/env bash
# @testcase: usage-libsdl2-image-r20-img-iswebp-rwops-returns-one
# @title: SDL2_image IMG_isWEBP returns 1 for a Pillow-encoded WEBP RWops stream
# @description: Generates an RGB WEBP via Pillow, opens it as an SDL_RWops, calls IMG_isWEBP on the RWops and asserts the return value equals 1 — pinning SDL2_image's WEBP probe through libwebp's signature recognition.
# @timeout: 180
# @tags: usage, libsdl2-image, webp, isWebp, rwops, r20
# @client: libsdl2-image

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.webp" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (50, 30), (40, 200, 90))
img.save(sys.argv[1], 'WEBP', quality=80)
PY

cat >"$tmpdir/probe.c" <<'C'
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc, char **argv) {
  if (argc < 2) return 64;
  SDL_RWops *rw = SDL_RWFromFile(argv[1], "rb");
  if (!rw) { fprintf(stderr, "RWFromFile failed: %s\n", SDL_GetError()); return 1; }
  int r = IMG_isWEBP(rw);
  printf("isWEBP=%d\n", r);
  SDL_RWclose(rw);
  return 0;
}
C

gcc "$tmpdir/probe.c" -o "$tmpdir/probe" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/probe" "$tmpdir/in.webp" >"$tmpdir/out.txt"
grep -q '^isWEBP=1$' "$tmpdir/out.txt" || {
    echo "expected isWEBP=1" >&2
    cat "$tmpdir/out.txt" >&2
    exit 1
}
