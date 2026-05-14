#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-rect-union-spans-both-rects
# @title: Pygame Rect.union produces the bounding rect covering both inputs
# @description: Computes Rect(0,0,10,10).union(Rect(5,5,20,20)) and asserts the union is (0,0,25,25), pinning the bounding-box union shape on Ubuntu 24.04 pygame.
# @timeout: 60
# @tags: usage, sdl, python, rect, union, r18
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
    a = pygame.Rect(0, 0, 10, 10)
    b = pygame.Rect(5, 5, 20, 20)
    u = a.union(b)
    assert tuple(u) == (0, 0, 25, 25), tuple(u)
finally:
    pygame.quit()
PY
