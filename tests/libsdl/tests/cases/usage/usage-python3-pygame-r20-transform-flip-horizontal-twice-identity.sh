#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-transform-flip-horizontal-twice-identity
# @title: Pygame transform.flip horizontally applied twice restores the original pixel
# @description: Builds a 4x4 Surface, sets pixel (0, 1) to a unique color, calls transform.flip(surf, True, False) twice, and asserts the pixel at (0, 1) matches the original color, confirming the horizontal flip operation is its own inverse.
# @timeout: 60
# @tags: usage, sdl, python, transform, flip, r20
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
    s = pygame.Surface((4, 4))
    s.fill((0, 0, 0))
    s.set_at((0, 1), (200, 100, 50))
    f1 = pygame.transform.flip(s, True, False)
    f2 = pygame.transform.flip(f1, True, False)
    p = f2.get_at((0, 1))
    assert (p.r, p.g, p.b) == (200, 100, 50), p
    print('ok flip-twice pixel=%s' % (p,))
finally:
    pygame.quit()
PY
