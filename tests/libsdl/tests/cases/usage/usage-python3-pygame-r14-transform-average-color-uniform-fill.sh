#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-transform-average-color-uniform-fill
# @title: Pygame transform.average_color returns the fill colour for a uniform surface
# @description: Fills a 4x4 surface with (12, 34, 56) and asserts pygame.transform.average_color returns the matching RGB triple.
# @timeout: 120
# @tags: usage, sdl, python, transform, color
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
    surf.fill((12, 34, 56))
    avg = pygame.transform.average_color(surf)
    assert avg[:3] == (12, 34, 56), avg
finally:
    pygame.quit()
PY
