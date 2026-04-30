#!/usr/bin/env bash
# @testcase: usage-python3-pygame-pixelarray-slice-indexing
# @title: pygame PixelArray slice indexing
# @description: Creates a PixelArray view over a pygame surface, fills a column with a mapped colour using slice indexing, releases the array, and verifies each pixel in that column matches via Surface.get_at.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-pixelarray-slice-indexing"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.init()
try:
    surface = pygame.Surface((5, 4))
    surface.fill((0, 0, 0))
    pixels = pygame.PixelArray(surface)
    blue = surface.map_rgb((0, 0, 255))
    pixels[2, :] = blue
    pixels[0, 0] = surface.map_rgb((255, 255, 0))
    del pixels

    for y in range(4):
        assert surface.get_at((2, y))[:3] == (0, 0, 255), (y, surface.get_at((2, y)))
    assert surface.get_at((0, 0))[:3] == (255, 255, 0)
    assert surface.get_at((1, 1))[:3] == (0, 0, 0)

    out_path = os.path.join(tmpdir, "pixelarray.bmp")
    pygame.image.save(surface, out_path)
    with open(out_path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM", head
    print("pixelarray-slice", surface.get_at((2, 0)), surface.get_at((0, 0)))
finally:
    pygame.quit()
PYCASE

grep -l BM "$tmpdir"/pixelarray.bmp >/dev/null
