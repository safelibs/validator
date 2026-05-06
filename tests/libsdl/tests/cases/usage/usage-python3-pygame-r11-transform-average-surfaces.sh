#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-transform-average-surfaces
# @title: Pygame transform.average_surfaces blends two solid colors
# @description: Calls transform.average_surfaces on two solid-red surfaces with intensities 100 and 50 and verifies the result is the per-channel mean (75, 0, 0).
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
    s1 = pygame.Surface((4, 4))
    s1.fill((100, 0, 0))
    s2 = pygame.Surface((4, 4))
    s2.fill((50, 0, 0))
    out = pygame.transform.average_surfaces([s1, s2])
    r, g, b, _ = out.get_at((0, 0))
    assert r == 75, r
    assert g == 0 and b == 0, (g, b)
    # Edge pixel matches center because both inputs are uniform.
    assert out.get_at((3, 3))[:3] == (75, 0, 0)
finally:
    pygame.quit()
PY
