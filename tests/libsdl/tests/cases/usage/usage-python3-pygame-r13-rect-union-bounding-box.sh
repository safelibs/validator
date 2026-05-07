#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-rect-union-bounding-box
# @title: Pygame Rect.union returns the bounding rectangle of two inputs
# @description: Builds two disjoint rectangles, calls Rect.union, and asserts the resulting rectangle spans both extents with the expected top-left corner and dimensions.
# @timeout: 60
# @tags: usage, sdl, python, rect
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
    a = pygame.Rect(5, 10, 4, 4)
    b = pygame.Rect(20, 30, 6, 6)
    u = a.union(b)
    # Bounding box from (5,10) to (26,36) => x=5, y=10, w=21, h=26
    assert u.topleft == (5, 10), u.topleft
    assert u.size == (21, 26), u.size
    assert u.right == 26 and u.bottom == 36
finally:
    pygame.quit()
PY
