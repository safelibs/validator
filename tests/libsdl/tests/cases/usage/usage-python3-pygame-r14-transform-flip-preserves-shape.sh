#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-transform-flip-preserves-shape
# @title: Pygame transform.flip preserves surface dimensions for both axes
# @description: Builds an 8x5 surface, calls pygame.transform.flip with flip_x=True/flip_y=False then with flip_x=False/flip_y=True, and asserts both flipped surfaces have the same (8, 5) size as the source.
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
    src = pygame.Surface((8, 5))
    src.fill((10, 20, 30))
    fx = pygame.transform.flip(src, True, False)
    fy = pygame.transform.flip(src, False, True)
    assert fx.get_size() == (8, 5), fx.get_size()
    assert fy.get_size() == (8, 5), fy.get_size()
finally:
    pygame.quit()
PY
