#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-rect-normalize-negative-dims
# @title: Pygame Rect.normalize converts negative width/height to positive coordinates
# @description: Constructs pygame.Rect(10, 10, -4, -3), calls .normalize(), and asserts the resulting topleft is (6, 7) and size is (4, 3) — the rectangle is moved so its origin is the top-left and the dimensions are positive.
# @timeout: 120
# @tags: usage, sdl, python, rect
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
    rect = pygame.Rect(10, 10, -4, -3)
    rect.normalize()
    assert rect.topleft == (6, 7), rect.topleft
    assert rect.size == (4, 3), rect.size
finally:
    pygame.quit()
PY
