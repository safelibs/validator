#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector2-distance-reflect
# @title: Pygame Vector2 distance and reflect
# @description: Validates pygame.math.Vector2 distance_to, normalize, and reflect operations against analytically known results.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector2-distance-reflect"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    a = pygame.math.Vector2(0, 0)
    b = pygame.math.Vector2(3, 4)
    assert math.isclose(a.distance_to(b), 5.0, abs_tol=1e-6)
    assert math.isclose(a.distance_squared_to(b), 25.0, abs_tol=1e-6)

    n = pygame.math.Vector2(3, 4).normalize()
    assert math.isclose(n.length(), 1.0, abs_tol=1e-6)
    assert math.isclose(n.x, 0.6, abs_tol=1e-6)
    assert math.isclose(n.y, 0.8, abs_tol=1e-6)

    incoming = pygame.math.Vector2(1, -1)
    reflected = incoming.reflect(pygame.math.Vector2(0, 1))
    assert math.isclose(reflected.x, 1.0, abs_tol=1e-6)
    assert math.isclose(reflected.y, 1.0, abs_tol=1e-6)
    print("vec", round(a.distance_to(b), 3), round(reflected.x, 1), round(reflected.y, 1))
finally:
    pygame.quit()
PY
