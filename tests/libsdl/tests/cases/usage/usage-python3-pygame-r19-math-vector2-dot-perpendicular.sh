#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-math-vector2-dot-perpendicular
# @title: Pygame math.Vector2 dot product is zero for perpendicular vectors
# @description: Constructs Vector2(1,0) and Vector2(0,1) and asserts their dot product equals zero exactly, pinning the dot-product orthogonality result for axis-aligned unit vectors.
# @timeout: 60
# @tags: usage, sdl, python, math, vector2, dot, r19
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
    a = pygame.math.Vector2(1, 0)
    b = pygame.math.Vector2(0, 1)
    d = a.dot(b)
    assert d == 0, d
finally:
    pygame.quit()
PY
