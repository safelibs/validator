#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-vector3-magnitude
# @title: Pygame Vector3 length and length_squared compute the 3D Euclidean norm
# @description: Builds Vector3(2,3,6), asserts length_squared returns 49.0 and length returns 7.0 (the 2-3-6-7 Pythagorean quadruple), and that the magnitude alias agrees with length.
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

pygame.init()
try:
    v = pygame.math.Vector3(2.0, 3.0, 6.0)
    assert abs(v.length_squared() - 49.0) < 1e-9, v.length_squared()
    assert abs(v.length() - 7.0) < 1e-9, v.length()
    assert abs(v.magnitude() - 7.0) < 1e-9, v.magnitude()
finally:
    pygame.quit()
PY
