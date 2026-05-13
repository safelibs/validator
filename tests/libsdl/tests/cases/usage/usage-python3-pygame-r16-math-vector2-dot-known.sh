#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-math-vector2-dot-known
# @title: Pygame math.Vector2(3,4) dot (5,6) equals the known value 39
# @description: Computes pygame.math.Vector2(3, 4).dot(Vector2(5, 6)) and asserts the result is exactly 39.0 — pinning the dot-product implementation on a small integer example.
# @timeout: 60
# @tags: usage, sdl, python, vector2, dot
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
    b = Vector2(5, 6)
    d = a.dot(b)
    assert d == 39.0, d
finally:
    pygame.quit()
PY
