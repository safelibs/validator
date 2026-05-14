#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-surface-set-alpha-getter-roundtrip
# @title: Pygame Surface.set_alpha value is reflected by get_alpha
# @description: Creates a Surface, calls set_alpha(128), and asserts get_alpha() returns 128, pinning the SDL alpha-property round trip via pygame.
# @timeout: 60
# @tags: usage, sdl, python, surface, alpha
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
    surf = pygame.Surface((8, 8))
    surf.set_alpha(128)
    got = surf.get_alpha()
    assert got == 128, got
finally:
    pygame.quit()
PY
