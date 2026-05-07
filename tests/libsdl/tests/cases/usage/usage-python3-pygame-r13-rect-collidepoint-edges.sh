#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-rect-collidepoint-edges
# @title: Pygame Rect.collidepoint includes the top-left corner and excludes the bottom-right
# @description: Builds a Rect at (10,20) sized 30x40 and asserts collidepoint returns True for the top-left corner and an interior point, but False for the exclusive bottom-right corner per Pygame's half-open rect convention.
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
    r = pygame.Rect(10, 20, 30, 40)
    assert r.collidepoint(10, 20) is True
    assert r.collidepoint(20, 30) is True
    # Bottom-right corner (x+w, y+h) is exclusive in pygame.
    assert r.collidepoint(40, 60) is False
    # Just outside on each axis.
    assert r.collidepoint(9, 20) is False
    assert r.collidepoint(10, 19) is False
finally:
    pygame.quit()
PY
