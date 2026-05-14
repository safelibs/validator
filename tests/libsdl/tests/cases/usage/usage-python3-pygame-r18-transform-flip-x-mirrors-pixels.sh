#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-transform-flip-x-mirrors-pixels
# @title: Pygame transform.flip horizontal mirrors a coloured-edge Surface
# @description: Sets the left column of a Surface to red, the right column to blue, calls pygame.transform.flip(s, True, False), and asserts the colours have swapped — pinning horizontal flip semantics through SDL2.
# @timeout: 60
# @tags: usage, sdl, python, transform, flip, r18
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
    W, H = 4, 3
    s = pygame.Surface((W, H))
    s.fill((0, 0, 0))
    for y in range(H):
        s.set_at((0, y), (255, 0, 0))
        s.set_at((W - 1, y), (0, 0, 255))
    flipped = pygame.transform.flip(s, True, False)
    lr, lg, lb, _ = flipped.get_at((0, 0))
    rr, rg, rb, _ = flipped.get_at((W - 1, 0))
    assert (lr, lg, lb) == (0, 0, 255), (lr, lg, lb)
    assert (rr, rg, rb) == (255, 0, 0), (rr, rg, rb)
finally:
    pygame.quit()
PY
