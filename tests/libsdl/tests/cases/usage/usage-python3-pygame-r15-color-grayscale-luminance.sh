#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-color-grayscale-luminance
# @title: Pygame Color.grayscale collapses RGB into a single luminance channel
# @description: Constructs pygame.Color(255, 0, 0) and calls .grayscale(), asserting the resulting Color has equal r, g, b channels (greyscale invariant) and an unchanged alpha of 255.
# @timeout: 60
# @tags: usage, sdl, python, color
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
    c = pygame.Color(255, 0, 0).grayscale()
    assert c.r == c.g == c.b, (c.r, c.g, c.b)
    assert c.a == 255, c.a
    # Pure red converts to a non-zero luminance.
    assert 0 < c.r < 255, c.r
finally:
    pygame.quit()
PY
