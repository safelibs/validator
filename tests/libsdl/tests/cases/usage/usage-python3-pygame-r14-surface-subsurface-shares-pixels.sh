#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-surface-subsurface-shares-pixels
# @title: Pygame Surface.subsurface shares pixel storage with the parent
# @description: Creates a 10x10 parent surface filled with black, slices a 4x4 subsurface at offset (2, 2), draws a single white pixel at the subsurface origin, and asserts the parent surface reads white at the corresponding parent coordinate (2, 2).
# @timeout: 120
# @tags: usage, sdl, python, surface
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
    parent = pygame.Surface((10, 10))
    parent.fill((0, 0, 0))
    sub = parent.subsurface(pygame.Rect(2, 2, 4, 4))
    sub.set_at((0, 0), (255, 255, 255))
    parent_pixel = parent.get_at((2, 2))[:3]
    assert parent_pixel == (255, 255, 255), parent_pixel
finally:
    pygame.quit()
PY
