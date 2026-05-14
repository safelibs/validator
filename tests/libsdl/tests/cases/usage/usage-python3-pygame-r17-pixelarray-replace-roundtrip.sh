#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-pixelarray-replace-roundtrip
# @title: Pygame PixelArray.replace swaps a colour and Surface.get_at confirms the change
# @description: Fills a Surface with a known colour, opens a PixelArray, replaces it with a new colour, and asserts Surface.get_at((0,0)) reports the new colour — exercising direct pixel rewrite through pygame's PixelArray wrapper.
# @timeout: 60
# @tags: usage, sdl, python, pixelarray
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
pygame.init()
try:
    surf = pygame.Surface((4, 4))
    surf.fill((10, 20, 30))
    pa = pygame.PixelArray(surf)
    try:
        pa.replace((10, 20, 30), (200, 100, 50))
    finally:
        del pa
    r, g, b, _ = surf.get_at((0, 0))
    assert (r, g, b) == (200, 100, 50), (r, g, b)
finally:
    pygame.quit()
PY
