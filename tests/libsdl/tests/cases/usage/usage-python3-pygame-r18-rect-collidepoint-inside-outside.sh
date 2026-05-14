#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-rect-collidepoint-inside-outside
# @title: Pygame Rect.collidepoint returns True for inside and False for outside
# @description: Builds a Rect at (10,20,30,40), asserts collidepoint((15,25)) is True and collidepoint((100,100)) is False, pinning the inclusive-left/exclusive-right Rect membership semantics on Ubuntu 24.04 pygame.
# @timeout: 60
# @tags: usage, sdl, python, rect, collidepoint, r18
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
    assert r.collidepoint((15, 25)) is True, r.collidepoint((15, 25))
    assert r.collidepoint((100, 100)) is False, r.collidepoint((100, 100))
finally:
    pygame.quit()
PY
