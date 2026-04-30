#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector2-angle-to
# @title: Pygame Vector2 angle_to
# @description: Computes the signed angle between two pygame.math.Vector2 instances using angle_to and verifies the result equals 90 degrees within a small tolerance.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector2-angle-to"
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
    a = pygame.math.Vector2(1, 0)
    b = pygame.math.Vector2(0, 1)
    angle = a.angle_to(b)
    assert abs(abs(angle) - 90.0) < 1e-6, angle
    reverse = b.angle_to(a)
    assert abs(abs(reverse) - 90.0) < 1e-6, reverse
    print("angle_to", angle, reverse)
finally:
    pygame.quit()
PY
