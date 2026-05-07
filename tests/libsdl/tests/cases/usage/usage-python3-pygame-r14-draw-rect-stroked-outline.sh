#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-draw-rect-stroked-outline
# @title: Pygame draw.rect with width=1 strokes the border but leaves the interior unfilled
# @description: Fills a 16x16 surface with black, draws a (255,0,0) stroked rectangle (4,4,8,8) with width=1 via pygame.draw.rect, and asserts the corner pixel is red while the interior pixel at (8, 8) remains black.
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
    pygame.draw.rect(surf, (255, 0, 0), pygame.Rect(4, 4, 8, 8), width=1)
    border = surf.get_at((4, 4))[:3]
    interior = surf.get_at((8, 8))[:3]
    assert border == (255, 0, 0), border
    assert interior == (0, 0, 0), interior
finally:
    pygame.quit()
PY
