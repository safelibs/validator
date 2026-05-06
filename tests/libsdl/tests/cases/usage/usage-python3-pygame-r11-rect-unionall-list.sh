#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-rect-unionall-list
# @title: Pygame Rect.unionall returns bounding rect of a list
# @description: Calls Rect.unionall on a list of three disjoint rects spanning a 30x30 area and confirms the result equals (0,0,30,30).
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
    r1 = pygame.Rect(0, 0, 10, 10)
    r2 = pygame.Rect(20, 0, 10, 10)
    r3 = pygame.Rect(0, 20, 10, 10)
    union = r1.unionall([r2, r3])
    assert union == pygame.Rect(0, 0, 30, 30), union
finally:
    pygame.quit()
PY
