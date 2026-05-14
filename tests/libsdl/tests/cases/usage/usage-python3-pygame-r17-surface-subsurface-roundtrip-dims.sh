#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-surface-subsurface-roundtrip-dims
# @title: Pygame Surface.subsurface within bounds returns the requested dimensions
# @description: Creates a 20x16 Surface, slices a (4,3)-(12,9) subsurface, and asserts get_size() returns (8, 6) — pinning the SDL-backed Surface region view dimensions.
# @timeout: 60
# @tags: usage, sdl, python, surface, subsurface
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
    surf = pygame.Surface((20, 16))
    sub = surf.subsurface(pygame.Rect(4, 3, 8, 6))
    assert sub.get_size() == (8, 6), sub.get_size()
finally:
    pygame.quit()
PY
