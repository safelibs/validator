#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-math-vector2-length-pythagoras
# @title: Pygame math.Vector2(3,4).length equals 5 by Pythagoras
# @description: Constructs pygame.math.Vector2(3,4) and asserts length() returns 5.0 within 1e-9 tolerance, pinning the Euclidean magnitude computation in the vector module.
# @timeout: 60
# @tags: usage, sdl, python, math, vector2, r19
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
    v = pygame.math.Vector2(3, 4)
    L = v.length()
    assert abs(L - 5.0) < 1e-9, L
    L2 = v.length_squared()
    assert L2 == 25, L2
finally:
    pygame.quit()
PY
