#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-surface-set-at-single-pixel-readback
# @title: Pygame Surface.set_at writes a single pixel observable via get_at
# @description: Fills an 8x8 Surface with a base colour, calls set_at((4,4),(200,100,50)) and asserts get_at((4,4)) returns the new colour while a neighbour at (4,5) keeps the base colour — pinning isolated pixel writes through SDL2.
# @timeout: 60
# @tags: usage, sdl, python, surface, set-at, r18
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
    s = pygame.Surface((8, 8))
    s.fill((10, 10, 10))
    s.set_at((4, 4), (200, 100, 50))
    r, g, b, _ = s.get_at((4, 4))
    assert (r, g, b) == (200, 100, 50), (r, g, b)
    nr, ng, nb, _ = s.get_at((4, 5))
    assert (nr, ng, nb) == (10, 10, 10), (nr, ng, nb)
finally:
    pygame.quit()
PY
