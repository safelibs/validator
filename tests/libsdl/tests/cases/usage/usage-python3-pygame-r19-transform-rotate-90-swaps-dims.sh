#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-transform-rotate-90-swaps-dims
# @title: Pygame transform.rotate 90 degrees swaps a non-square Surface's dimensions
# @description: Rotates a 4x10 Surface by 90 degrees via pygame.transform.rotate and asserts the resulting Surface size is (10,4), pinning the 90-degree axis-swap contract through SDL2.
# @timeout: 60
# @tags: usage, sdl, python, transform, rotate, r19
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
    s = pygame.Surface((4, 10))
    s.fill((255, 0, 0))
    rotated = pygame.transform.rotate(s, 90)
    assert rotated.get_size() == (10, 4), rotated.get_size()
finally:
    pygame.quit()
PY
