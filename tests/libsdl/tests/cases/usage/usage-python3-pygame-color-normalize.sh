#!/usr/bin/env bash
# @testcase: usage-python3-pygame-color-normalize
# @title: pygame Color.normalize float channels
# @description: Constructs a pygame.Color from 8-bit RGBA components and confirms Color.normalize returns the matching unit-interval floats with each component equal to the integer divided by 255.
# @timeout: 120
# @tags: usage, color
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-color-normalize"

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    c = pygame.Color(51, 102, 204, 255)
    r, g, b, a = c.normalize()
    assert abs(r - 51 / 255) < 1e-9, r
    assert abs(g - 102 / 255) < 1e-9, g
    assert abs(b - 204 / 255) < 1e-9, b
    assert abs(a - 1.0) < 1e-9, a
    for v in (r, g, b, a):
        assert 0.0 <= v <= 1.0, v
    print("normalize", round(r, 4), round(g, 4), round(b, 4), round(a, 4))
finally:
    pygame.quit()
PY
