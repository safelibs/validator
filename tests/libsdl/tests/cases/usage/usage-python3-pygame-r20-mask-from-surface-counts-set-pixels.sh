#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-mask-from-surface-counts-set-pixels
# @title: Pygame mask.from_surface counts only opaque pixels as set
# @description: Builds a 4x4 Surface with per-pixel alpha, sets two pixels to fully-opaque white and the rest transparent, calls mask.from_surface, and asserts mask.count() returns exactly 2, confirming SDL-backed mask construction treats only sufficiently-opaque pixels as set.
# @timeout: 60
# @tags: usage, sdl, python, mask, r20
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
    s = pygame.Surface((4, 4), pygame.SRCALPHA)
    s.fill((0, 0, 0, 0))
    s.set_at((1, 1), (255, 255, 255, 255))
    s.set_at((2, 3), (255, 255, 255, 255))
    m = pygame.mask.from_surface(s)
    n = m.count()
    assert n == 2, n
    assert m.get_size() == (4, 4), m.get_size()
    print('ok mask.count=%d' % n)
finally:
    pygame.quit()
PY
