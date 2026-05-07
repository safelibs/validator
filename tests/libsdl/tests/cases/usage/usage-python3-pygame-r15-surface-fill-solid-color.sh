#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-surface-fill-solid-color
# @title: Pygame Surface.fill paints every probed pixel with the requested RGB color
# @description: Creates a 6x4 surface, calls fill((30, 60, 90)), and asserts get_at on three sampled pixels (corner, center, far corner) returns RGB (30, 60, 90) confirming a uniform fill.
# @timeout: 120
# @tags: usage, sdl, python, surface
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
    surf = pygame.Surface((6, 4))
    surf.fill((30, 60, 90))
    for px in [(0, 0), (3, 2), (5, 3)]:
        rgb = surf.get_at(px)[:3]
        assert rgb == (30, 60, 90), (px, rgb)
finally:
    pygame.quit()
PY
