#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-font-size-returns-positive
# @title: Pygame Font.size returns positive width and height for non-empty text
# @description: Constructs the default Font at size 16 and asserts Font.size for a multi-character string returns positive integer width and height greater than zero.
# @timeout: 120
# @tags: usage, sdl, python, font
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame

pygame.font.init()
try:
    font = pygame.font.Font(None, 16)
    w, h = font.size("hello-r12")
    assert isinstance(w, int) and isinstance(h, int)
    assert w > 0, w
    assert h > 0, h
    we, he = font.size("")
    assert we == 0, we
    assert he > 0, he
finally:
    pygame.font.quit()
PY
