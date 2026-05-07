#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-transform-rotate-90-swaps-dims
# @title: Pygame transform.rotate by 90 degrees swaps width and height
# @description: Rotates a 6x4 surface by 90 degrees with pygame.transform.rotate and asserts the resulting surface size is (4, 6).
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
    src = pygame.Surface((6, 4))
    src.fill((10, 20, 30))
    rot = pygame.transform.rotate(src, 90)
    assert rot.get_size() == (4, 6), rot.get_size()
finally:
    pygame.quit()
PY
