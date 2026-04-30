#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector2-lerp
# @title: Pygame Vector2 lerp
# @description: Linearly interpolates between two pygame.math.Vector2 instances at t=0, t=1, and t=0.25 and verifies each result matches the analytical formula.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector2-lerp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.init()
try:
    start = pygame.math.Vector2(0.0, 10.0)
    end = pygame.math.Vector2(8.0, 2.0)

    at_zero = start.lerp(end, 0.0)
    at_one = start.lerp(end, 1.0)
    at_quarter = start.lerp(end, 0.25)

    assert isinstance(at_quarter, pygame.math.Vector2), type(at_quarter)
    assert abs(at_zero.x - 0.0) < 1e-9 and abs(at_zero.y - 10.0) < 1e-9, at_zero
    assert abs(at_one.x - 8.0) < 1e-9 and abs(at_one.y - 2.0) < 1e-9, at_one
    # 0.25 of the way: x = 2.0, y = 8.0
    assert abs(at_quarter.x - 2.0) < 1e-9, at_quarter.x
    assert abs(at_quarter.y - 8.0) < 1e-9, at_quarter.y

    print(case_id, "ok", at_quarter)
finally:
    pygame.quit()
PY
