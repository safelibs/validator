#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-draw-aaline-endpoint-painted
# @title: Pygame draw.aaline paints a non-background pixel at the start endpoint
# @description: Fills a 16x16 surface with black, draws an antialiased line from (2, 2) to (12, 12) in white via pygame.draw.aaline, and asserts the pixel at (2, 2) is no longer pure black (the AA line painted at least the starting endpoint).
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
    pygame.draw.aaline(surf, (255, 255, 255), (2, 2), (12, 12))
    pix = surf.get_at((2, 2))[:3]
    assert pix != (0, 0, 0), pix
finally:
    pygame.quit()
PY
