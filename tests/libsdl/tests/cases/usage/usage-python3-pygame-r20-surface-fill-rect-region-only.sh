#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-surface-fill-rect-region-only
# @title: Pygame Surface.fill with a rect argument fills only the specified region
# @description: Builds a 6x6 Surface initially filled with (0, 0, 0), then calls fill((255, 0, 0), pygame.Rect(2, 2, 2, 2)), asserts the pixel at (3, 3) is red and the pixel at (0, 0) remains black, confirming SDL-backed rect-bounded fill respects the supplied region.
# @timeout: 60
# @tags: usage, sdl, python, surface, fill, r20
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
    s = pygame.Surface((6, 6))
    s.fill((0, 0, 0))
    s.fill((255, 0, 0), pygame.Rect(2, 2, 2, 2))
    inside = s.get_at((3, 3))
    outside = s.get_at((0, 0))
    assert (inside.r, inside.g, inside.b) == (255, 0, 0), inside
    assert (outside.r, outside.g, outside.b) == (0, 0, 0), outside
    print('ok inside=%s outside=%s' % (inside, outside))
finally:
    pygame.quit()
PY
