#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-draw-line-midpoint-pixel-readback
# @title: Pygame draw.line midpoint pixel readback matches the requested colour
# @description: Draws a horizontal line on a black 11x11 Surface and asserts Surface.get_at on the midpoint returns the requested colour, pinning the basic line rasterisation path through SDL2's renderer-less Surface drawing.
# @timeout: 60
# @tags: usage, sdl, python, draw
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
    surf = pygame.Surface((11, 11))
    surf.fill((0, 0, 0))
    pygame.draw.line(surf, (255, 128, 64), (0, 5), (10, 5), 1)
    r, g, b, _ = surf.get_at((5, 5))
    assert (r, g, b) == (255, 128, 64), (r, g, b)
finally:
    pygame.quit()
PY
