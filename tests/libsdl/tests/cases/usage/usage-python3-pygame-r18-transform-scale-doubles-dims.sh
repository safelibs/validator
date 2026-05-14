#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-transform-scale-doubles-dims
# @title: Pygame transform.scale doubles Surface dimensions to the requested size
# @description: Scales a 5x4 Surface to (10,8) via pygame.transform.scale and asserts get_size returns (10,8), pinning the explicit-target-size scaling contract through SDL2.
# @timeout: 60
# @tags: usage, sdl, python, transform, scale, r18
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
    s = pygame.Surface((5, 4))
    s.fill((50, 100, 150))
    scaled = pygame.transform.scale(s, (10, 8))
    assert scaled.get_size() == (10, 8), scaled.get_size()
finally:
    pygame.quit()
PY
