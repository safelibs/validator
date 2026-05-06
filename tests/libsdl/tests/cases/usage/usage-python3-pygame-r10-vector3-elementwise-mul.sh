#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-vector3-elementwise-mul
# @title: Pygame Vector3.elementwise multiplication
# @description: Performs an elementwise (Hadamard) product between two Vector3 instances and verifies each component matches the per-axis product.
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
    a = pygame.math.Vector3(2.0, 3.0, 4.0)
    b = pygame.math.Vector3(5.0, 6.0, 7.0)
    product = a.elementwise() * b
    assert math.isclose(product.x, 10.0, abs_tol=1e-6)
    assert math.isclose(product.y, 18.0, abs_tol=1e-6)
    assert math.isclose(product.z, 28.0, abs_tol=1e-6)

    # Elementwise division.
    quotient = a.elementwise() / b
    assert math.isclose(quotient.x, 2.0 / 5.0, abs_tol=1e-6)
    assert math.isclose(quotient.y, 3.0 / 6.0, abs_tol=1e-6)
    assert math.isclose(quotient.z, 4.0 / 7.0, abs_tol=1e-6)
finally:
    pygame.quit()
PY
