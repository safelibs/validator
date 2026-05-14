#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-rect-inflate-grows-equally-each-side
# @title: Pygame Rect.inflate expands width and height symmetrically
# @description: Inflates a Rect(10,20,30,40) by (10,20) and asserts the new rect is (5,10,40,60) — pinning that inflate distributes growth half on each side as documented.
# @timeout: 60
# @tags: usage, sdl, python, rect, inflate, r18
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
    inflated = r.inflate(10, 20)
    assert tuple(inflated) == (5, 10, 40, 60), tuple(inflated)
finally:
    pygame.quit()
PY
