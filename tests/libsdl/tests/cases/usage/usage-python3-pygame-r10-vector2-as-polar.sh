#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-vector2-as-polar
# @title: Pygame Vector2 as_polar / from_polar roundtrip
# @description: Converts a Vector2 to polar (r, theta), reconstructs via from_polar, and verifies the roundtrip recovers the original cartesian coordinates.
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
    original = pygame.math.Vector2(3.0, 4.0)
    r, theta = original.as_polar()
    assert math.isclose(r, 5.0, abs_tol=1e-6)
    # atan2(4, 3) in degrees ~= 53.13
    assert math.isclose(theta, math.degrees(math.atan2(4.0, 3.0)), abs_tol=1e-6)

    rebuilt = pygame.math.Vector2()
    rebuilt.from_polar((r, theta))
    assert math.isclose(rebuilt.x, original.x, abs_tol=1e-6)
    assert math.isclose(rebuilt.y, original.y, abs_tol=1e-6)
finally:
    pygame.quit()
PY
