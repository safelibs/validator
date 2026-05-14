#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-rect-move-preserves-size
# @title: Pygame Rect.move shifts position while preserving width and height
# @description: Moves a Rect(5,5,20,30) by (3,4) and asserts the result is (8,9,20,30), pinning that move returns a new Rect with shifted origin and unchanged size.
# @timeout: 60
# @tags: usage, sdl, python, rect, move, r18
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
    r = pygame.Rect(5, 5, 20, 30)
    m = r.move(3, 4)
    assert tuple(m) == (8, 9, 20, 30), tuple(m)
    # The original is unchanged because move returns a copy.
    assert tuple(r) == (5, 5, 20, 30), tuple(r)
finally:
    pygame.quit()
PY
