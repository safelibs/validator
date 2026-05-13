#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-transform-flip-horizontal-roundtrip
# @title: Pygame transform.flip horizontal applied twice returns the same pixel values
# @description: Builds a 4x4 Surface with a known gradient, flips horizontally twice via transform.flip(surf, True, False), and asserts the doubly-flipped Surface has identical get_at values to the original at every pixel.
# @timeout: 120
# @tags: usage, sdl, python, transform, flip
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
    surf = pygame.Surface((4, 4))
    for y in range(4):
        for x in range(4):
            surf.set_at((x, y), (x * 30, y * 30, 80))
    once = pygame.transform.flip(surf, True, False)
    twice = pygame.transform.flip(once, True, False)
    for y in range(4):
        for x in range(4):
            a = surf.get_at((x, y))[:3]
            b = twice.get_at((x, y))[:3]
            assert a == b, (x, y, a, b)
finally:
    pygame.quit()
PY
