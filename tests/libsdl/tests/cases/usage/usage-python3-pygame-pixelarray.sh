#!/usr/bin/env bash
# @testcase: usage-python3-pygame-pixelarray
# @title: Pygame pixelarray write
# @description: Writes a pixel through Pygame PixelArray and verifies the updated surface color.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-pixelarray"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    surface = pygame.Surface((4, 4))
    pixels = pygame.PixelArray(surface)
    pixels[1][1] = surface.map_rgb((255, 0, 0))
    del pixels
    assert surface.get_at((1, 1)).r == 255
    print("pixel", surface.get_at((1, 1)))
finally:
    pygame.quit()
PY
