#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-rect-move-shifts-topleft
# @title: Pygame Rect.move returns a new Rect with the offset applied to topleft and unchanged size
# @description: Builds Rect(5, 6, 8, 9), calls .move(3, 4), and asserts the resulting Rect has topleft (8, 10), size (8, 9) and that the original rectangle is left unchanged at topleft (5, 6).
# @timeout: 60
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
    a = pygame.Rect(5, 6, 8, 9)
    b = a.move(3, 4)
    assert b.topleft == (8, 10), b.topleft
    assert b.size == (8, 9), b.size
    # Original is not mutated by .move.
    assert a.topleft == (5, 6), a.topleft
finally:
    pygame.quit()
PY
