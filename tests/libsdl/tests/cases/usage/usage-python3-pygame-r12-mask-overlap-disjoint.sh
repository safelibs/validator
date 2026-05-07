#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-mask-overlap-disjoint
# @title: Pygame Mask.overlap returns None for disjoint mask regions
# @description: Builds two filled 4x4 masks and calls overlap with an offset that places them in non-overlapping positions, asserting overlap returns None.
# @timeout: 120
# @tags: usage, sdl, python, mask
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
    a = pygame.mask.Mask((4, 4), fill=True)
    b = pygame.mask.Mask((4, 4), fill=True)
    # Offset puts b far enough that it does not overlap a.
    assert a.overlap(b, (10, 10)) is None
    # Sanity check: zero offset places them on top of each other and overlaps.
    hit = a.overlap(b, (0, 0))
    assert hit is not None
finally:
    pygame.quit()
PY
