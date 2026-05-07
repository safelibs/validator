#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-transform-scale-target-dimensions
# @title: Pygame transform.scale resizes a surface to the requested target dimensions
# @description: Builds an 8x4 source surface, calls pygame.transform.scale(src, (16, 12)), and asserts the resulting surface has size exactly (16, 12), confirming the explicit target dimensions are honored.
# @timeout: 120
# @tags: usage, sdl, python, transform
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
    src = pygame.Surface((8, 4))
    src.fill((50, 50, 50))
    out = pygame.transform.scale(src, (16, 12))
    assert out.get_size() == (16, 12), out.get_size()
finally:
    pygame.quit()
PY
