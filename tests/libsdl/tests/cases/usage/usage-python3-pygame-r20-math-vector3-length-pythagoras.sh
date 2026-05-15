#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-math-vector3-length-pythagoras
# @title: Pygame math.Vector3 length equals 3D Pythagorean magnitude
# @description: Constructs pygame.math.Vector3(2, 3, 6), asserts .length() equals 7.0 to within 1e-9 (since sqrt(4+9+36)==7), confirming SDL-backed Vector3 magnitude follows the 3D Pythagorean formula.
# @timeout: 60
# @tags: usage, sdl, python, math, vector3, r20
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
    v = pygame.math.Vector3(2, 3, 6)
    L = v.length()
    assert abs(L - 7.0) < 1e-9, L
    print('ok length=%.6f' % L)
finally:
    pygame.quit()
PY
