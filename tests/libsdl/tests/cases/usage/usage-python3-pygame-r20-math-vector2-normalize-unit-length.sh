#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-math-vector2-normalize-unit-length
# @title: Pygame Vector2 normalize returns a unit-length vector
# @description: Constructs pygame.math.Vector2(3, 4), calls .normalize(), asserts the result has length 1.0 within 1e-9 and components 0.6 and 0.8 within 1e-9 each, confirming SDL-backed Vector2 normalization yields a unit vector preserving direction.
# @timeout: 60
# @tags: usage, sdl, python, math, vector2, normalize, r20
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
pygame.init()
try:
    v = pygame.math.Vector2(3, 4)
    n = v.normalize()
    assert abs(n.length() - 1.0) < 1e-9, n.length()
    assert abs(n.x - 0.6) < 1e-9, n.x
    assert abs(n.y - 0.8) < 1e-9, n.y
    print('ok normalize x=%.6f y=%.6f' % (n.x, n.y))
finally:
    pygame.quit()
PY
