#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector2-rotate
# @title: pygame Vector2 rotate
# @description: Exercises pygame vector2 rotate through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector2-rotate"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    value = pygame.math.Vector2(1, 0).rotate(90)
    assert math.isclose(value.x, 0.0, abs_tol=1e-6)
    assert math.isclose(value.y, 1.0, abs_tol=1e-6)
    print(round(value.y, 1))
finally:
    pygame.quit()
PYCASE
