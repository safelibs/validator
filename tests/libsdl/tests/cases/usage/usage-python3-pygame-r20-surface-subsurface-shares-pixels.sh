#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-surface-subsurface-shares-pixels
# @title: Pygame Surface.subsurface shares pixel memory with the parent
# @description: Builds an 8x8 Surface filled with black, creates a 4x4 subsurface starting at (2, 2), writes a green pixel at (0, 0) in the subsurface, and asserts the parent's pixel at (2, 2) is now green, confirming SDL-backed subsurface aliases the parent's pixel buffer.
# @timeout: 60
# @tags: usage, sdl, python, surface, subsurface, r20
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
    parent = pygame.Surface((8, 8))
    parent.fill((0, 0, 0))
    sub = parent.subsurface(pygame.Rect(2, 2, 4, 4))
    sub.set_at((0, 0), (0, 255, 0))
    p = parent.get_at((2, 2))
    assert (p.r, p.g, p.b) == (0, 255, 0), p
    print('ok subsurface-shares parent=%s' % (p,))
finally:
    pygame.quit()
PY
