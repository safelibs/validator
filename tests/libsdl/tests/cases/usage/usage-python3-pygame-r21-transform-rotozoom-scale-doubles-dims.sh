#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-transform-rotozoom-scale-doubles-dims
# @title: Pygame transform.rotozoom with angle 0 and scale 2 doubles a surface's dimensions
# @description: Builds an 8x6 Surface, calls transform.rotozoom(surf, 0.0, 2.0), and asserts the result Surface has size (16, 12), pinning the SDL-backed rotozoom helper's pure-scale branch when the angle is zero.
# @timeout: 60
# @tags: usage, sdl, python, transform, rotozoom, r21
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
    s = pygame.Surface((8, 6))
    s.fill((10, 20, 30))
    r = pygame.transform.rotozoom(s, 0.0, 2.0)
    assert r.get_size() == (16, 12), r.get_size()
finally:
    pygame.quit()
PY
