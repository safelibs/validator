#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector3-dot
# @title: pygame Vector3 dot product
# @description: Computes pygame.math.Vector3.dot for orthogonal and parallel pairs and verifies the scalar matches the analytical sum of component products.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector3-dot"
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
    a = pygame.math.Vector3(1.0, 2.0, 3.0)
    b = pygame.math.Vector3(4.0, -5.0, 6.0)
    expected = 1.0 * 4.0 + 2.0 * -5.0 + 3.0 * 6.0
    got = a.dot(b)
    assert math.isclose(got, expected, rel_tol=1e-9)
    # Orthogonal basis vectors give zero.
    ortho = pygame.math.Vector3(1, 0, 0).dot(pygame.math.Vector3(0, 1, 0))
    assert math.isclose(ortho, 0.0)
    # Self-dot equals length squared.
    self_dot = a.dot(a)
    assert math.isclose(self_dot, a.length_squared(), rel_tol=1e-9)
    print("dot", got, "ortho", ortho, "self", self_dot)
finally:
    pygame.quit()
PY
