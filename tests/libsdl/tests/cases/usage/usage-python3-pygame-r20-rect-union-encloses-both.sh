#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-rect-union-encloses-both
# @title: Pygame Rect.union returns the smallest rect enclosing two disjoint rects
# @description: Builds Rect(0, 0, 4, 4) and Rect(10, 6, 2, 3), calls .union, and asserts the result has left=0, top=0, right=12, bottom=9, exactly the bounding box of the inputs, confirming SDL-backed union covers both source rectangles.
# @timeout: 60
# @tags: usage, sdl, python, rect, union, r20
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
    a = pygame.Rect(0, 0, 4, 4)
    b = pygame.Rect(10, 6, 2, 3)
    u = a.union(b)
    assert u.left == 0 and u.top == 0, u
    assert u.right == 12 and u.bottom == 9, u
    print('ok union=%s' % (u,))
finally:
    pygame.quit()
PY
