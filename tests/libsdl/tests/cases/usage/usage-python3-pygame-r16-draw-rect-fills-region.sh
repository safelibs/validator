#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-draw-rect-fills-region
# @title: Pygame draw.rect paints the interior of a rect to the requested color
# @description: Creates a 16x16 Surface filled black, calls pygame.draw.rect with color (200, 50, 25) over a (4,4,8,8) rect, and asserts get_at on a center pixel of the painted region (e.g. (8, 8)) returns RGB (200, 50, 25).
# @timeout: 120
# @tags: usage, sdl, python, draw, rect
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
    pygame.draw.rect(surf, (200, 50, 25), pygame.Rect(4, 4, 8, 8))
    rgb = surf.get_at((8, 8))[:3]
    assert rgb == (200, 50, 25), rgb
    corner = surf.get_at((0, 0))[:3]
    assert corner == (0, 0, 0), corner
finally:
    pygame.quit()
PY
