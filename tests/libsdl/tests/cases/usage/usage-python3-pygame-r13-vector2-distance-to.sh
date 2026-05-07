#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-vector2-distance-to
# @title: Pygame Vector2.distance_to returns the Euclidean distance between two points
# @description: Builds Vector2(0,0) and Vector2(3,4), asserts distance_to returns 5.0 (3-4-5 triangle), and that distance_squared_to returns 25.0 for the same pair.
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
    a = pygame.math.Vector2(0.0, 0.0)
    b = pygame.math.Vector2(3.0, 4.0)
    d = a.distance_to(b)
    d2 = a.distance_squared_to(b)
    assert abs(d - 5.0) < 1e-9, d
    assert abs(d2 - 25.0) < 1e-9, d2
    # distance is symmetric.
    assert abs(b.distance_to(a) - 5.0) < 1e-9
finally:
    pygame.quit()
PY
