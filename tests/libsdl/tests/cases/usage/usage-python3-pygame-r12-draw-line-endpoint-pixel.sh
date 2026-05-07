#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-draw-line-endpoint-pixel
# @title: Pygame draw.line paints both endpoint pixels with the line color
# @description: Draws a horizontal line on a black surface from (2, 4) to (10, 4) and asserts get_at at both endpoints returns the line color while a pixel above the line stays black.
# @timeout: 120
# @tags: usage, sdl, python, draw, line
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
    pygame.draw.line(surf, (240, 200, 0), (2, 4), (10, 4), 1)
    a = surf.get_at((2, 4))[:3]
    b = surf.get_at((10, 4))[:3]
    off = surf.get_at((6, 0))[:3]
    assert a == (240, 200, 0), a
    assert b == (240, 200, 0), b
    assert off == (0, 0, 0), off
finally:
    pygame.quit()
PY
