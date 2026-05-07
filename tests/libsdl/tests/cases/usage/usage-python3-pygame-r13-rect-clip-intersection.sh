#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-rect-clip-intersection
# @title: Pygame Rect.clip returns the intersection of two overlapping rectangles
# @description: Builds two overlapping rectangles, computes Rect.clip, and asserts the resulting Rect represents their intersection at the expected position and size.
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
    a = pygame.Rect(0, 0, 20, 20)
    b = pygame.Rect(10, 5, 20, 20)
    c = a.clip(b)
    # Intersection: x=10, y=5, width=10, height=15
    assert c.topleft == (10, 5), c.topleft
    assert c.size == (10, 15), c.size

    # Disjoint rectangles produce a zero-area Rect.
    d = a.clip(pygame.Rect(100, 100, 5, 5))
    assert d.size == (0, 0), d.size
finally:
    pygame.quit()
PY
