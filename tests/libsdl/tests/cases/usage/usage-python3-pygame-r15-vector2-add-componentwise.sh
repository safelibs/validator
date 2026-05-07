#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-vector2-add-componentwise
# @title: Pygame Vector2 addition adds components and preserves operand types
# @description: Constructs Vector2(3, 4) and Vector2(1, 2), computes their sum, and asserts the result has x=4.0 and y=6.0 with type Vector2; the source vectors retain their original components.
# @timeout: 60
# @tags: usage, sdl, python, vector
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
from pygame.math import Vector2

pygame.init()
try:
    a = Vector2(3, 4)
    b = Vector2(1, 2)
    c = a + b
    assert isinstance(c, Vector2), type(c)
    assert c.x == 4.0, c.x
    assert c.y == 6.0, c.y
    # Operands unmodified.
    assert (a.x, a.y) == (3.0, 4.0)
    assert (b.x, b.y) == (1.0, 2.0)
finally:
    pygame.quit()
PY
