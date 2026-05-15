#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-rect-contains-strict-inside
# @title: Pygame Rect.contains reports True for a strictly enclosed Rect and False otherwise
# @description: Builds an outer Rect(0,0,100,100) and asserts contains(Rect(10,10,50,50)) is True while contains(Rect(80,80,50,50)) is False, pinning the strict-inside Rect containment contract.
# @timeout: 60
# @tags: usage, sdl, python, rect, contains, r19
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
    outer = pygame.Rect(0, 0, 100, 100)
    inside = pygame.Rect(10, 10, 50, 50)
    overlap = pygame.Rect(80, 80, 50, 50)
    assert outer.contains(inside) is True
    assert outer.contains(overlap) is False
finally:
    pygame.quit()
PY
