#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-draw-circle-fills-center-pixel
# @title: Pygame draw.circle fills the center pixel with the requested color
# @description: Draws a filled circle of radius 4 centered at (8, 8) on a black 16x16 surface and asserts get_at at the center returns the requested fill color.
# @timeout: 120
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
    surf = pygame.Surface((16, 16))
    surf.fill((0, 0, 0))
    pygame.draw.circle(surf, (200, 100, 50), (8, 8), 4)
    r, g, b, _ = surf.get_at((8, 8))
    assert (r, g, b) == (200, 100, 50), (r, g, b)
    r2, g2, b2, _ = surf.get_at((0, 0))
    assert (r2, g2, b2) == (0, 0, 0), (r2, g2, b2)
finally:
    pygame.quit()
PY
