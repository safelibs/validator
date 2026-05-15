#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-rect-clamp-inside-larger-rect
# @title: Pygame Rect.clamp keeps a smaller rect inside a larger bounding rect
# @description: Calls Rect(100,100,10,10).clamp(Rect(0,0,50,50)) and asserts the clamped rect is positioned at (40,40,10,10), pinning the clamp-against-bounds semantics on Ubuntu 24.04 pygame.
# @timeout: 60
# @tags: usage, sdl, python, rect, clamp, r19
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
    inner = pygame.Rect(100, 100, 10, 10)
    bounds = pygame.Rect(0, 0, 50, 50)
    clamped = inner.clamp(bounds)
    assert tuple(clamped) == (40, 40, 10, 10), tuple(clamped)
finally:
    pygame.quit()
PY
