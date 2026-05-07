#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-surface-set-at-get-at-roundtrip
# @title: Pygame Surface set_at and get_at round-trip an RGBA pixel
# @description: Creates an SRCALPHA Surface, writes a known RGBA color with set_at at (3,2), and asserts get_at returns the same 4-tuple.
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
    surf = pygame.Surface((8, 8), pygame.SRCALPHA)
    surf.fill((0, 0, 0, 0))
    surf.set_at((3, 2), (10, 200, 50, 128))
    px = surf.get_at((3, 2))
    assert tuple(px) == (10, 200, 50, 128), tuple(px)
    other = surf.get_at((0, 0))
    assert tuple(other) == (0, 0, 0, 0), tuple(other)
finally:
    pygame.quit()
PY
