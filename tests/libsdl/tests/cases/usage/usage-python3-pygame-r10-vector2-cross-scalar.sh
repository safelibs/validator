#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-vector2-cross-scalar
# @title: Pygame Vector2.cross returns scalar 2D cross product
# @description: Computes the 2D cross product via Vector2.cross and verifies sign and magnitude against the analytic value (x1*y2 - y1*x2).
# @timeout: 120
# @tags: usage, sdl, python, math
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import math
import pygame

pygame.init()
try:
    a = pygame.math.Vector2(2.0, 3.0)
    b = pygame.math.Vector2(4.0, 1.0)
    expected = 2.0 * 1.0 - 3.0 * 4.0  # -10.0
    assert math.isclose(a.cross(b), expected, abs_tol=1e-6)
    # Anti-symmetric: a x b == -(b x a)
    assert math.isclose(b.cross(a), -expected, abs_tol=1e-6)
    # Parallel vectors -> zero cross product.
    parallel = pygame.math.Vector2(1.0, 2.0).cross(pygame.math.Vector2(3.0, 6.0))
    assert math.isclose(parallel, 0.0, abs_tol=1e-6)
finally:
    pygame.quit()
PY
