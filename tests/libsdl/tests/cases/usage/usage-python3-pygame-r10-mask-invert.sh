#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-mask-invert
# @title: Pygame Mask.invert flips every bit
# @description: Sets a subset of bits in a mask, calls invert(), and verifies the previously unset bits are now set and previously set bits are clear.
# @timeout: 120
# @tags: usage, sdl, python
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
    mask = pygame.mask.Mask((8, 8))
    set_points = [(0, 0), (1, 2), (5, 5), (7, 7)]
    for pt in set_points:
        mask.set_at(pt, 1)
    assert mask.count() == len(set_points)

    mask.invert()
    # After invert(), exactly (8*8 - len(set_points)) bits should be set.
    assert mask.count() == 64 - len(set_points)
    for pt in set_points:
        assert mask.get_at(pt) == 0
    assert mask.get_at((0, 1)) == 1
    assert mask.get_at((4, 4)) == 1
finally:
    pygame.quit()
PY
