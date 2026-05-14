#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-surface-fill-then-get-at-roundtrip
# @title: Pygame Surface.fill colour reads back via get_at on multiple coordinates
# @description: Fills a 6x6 Surface with (12,34,56) and asserts get_at returns the same RGB triple at three different coordinates, pinning the SDL surface fill + pixel readback round trip.
# @timeout: 60
# @tags: usage, sdl, python, surface, fill, get-at, r18
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
    s = pygame.Surface((6, 6))
    s.fill((12, 34, 56))
    for x, y in ((0, 0), (3, 2), (5, 5)):
        r, g, b, _ = s.get_at((x, y))
        assert (r, g, b) == (12, 34, 56), (x, y, r, g, b)
finally:
    pygame.quit()
PY
