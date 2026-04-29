#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector3-cross
# @title: pygame Vector3 cross product
# @description: Computes the pygame Vector3 cross product of unit X and unit Y and verifies the result equals the unit Z basis vector.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector3-cross"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import os
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    result = pygame.math.Vector3(1, 0, 0).cross(pygame.math.Vector3(0, 1, 0))
    assert (result.x, result.y, result.z) == (0.0, 0.0, 1.0)
    print("cross", result)
finally:
    pygame.quit()
PY
