#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-transform-smoothscale-by-doubles
# @title: Pygame transform.smoothscale_by doubles surface dimensions with factor 2.0
# @description: Builds a 4x3 RGB surface, calls pygame.transform.smoothscale_by with factor 2.0, and asserts the resulting surface size is (8, 6).
# @timeout: 120
# @tags: usage, sdl, python, transform
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
    src = pygame.Surface((4, 3))
    src.fill((50, 60, 70))
    out = pygame.transform.smoothscale_by(src, 2.0)
    assert out.get_size() == (8, 6), out.get_size()
finally:
    pygame.quit()
PY
