#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-rect-collidelistall
# @title: Pygame Rect.collidelistall returns all overlapping indices
# @description: Builds a list of Rects and verifies Rect.collidelistall returns every index whose rect intersects the probe.
# @timeout: 120
# @tags: usage, sdl, python
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
    rects = [
        pygame.Rect(0, 0, 10, 10),     # 0 - overlaps probe
        pygame.Rect(100, 100, 5, 5),   # 1 - far away
        pygame.Rect(5, 5, 20, 20),     # 2 - overlaps probe
        pygame.Rect(50, 0, 10, 10),    # 3 - non-overlap
        pygame.Rect(8, 8, 4, 4),       # 4 - inside probe
    ]
    probe = pygame.Rect(0, 0, 15, 15)
    indices = probe.collidelistall(rects)
    assert sorted(indices) == [0, 2, 4]

    no_match = pygame.Rect(200, 200, 1, 1).collidelistall(rects)
    assert no_match == []
finally:
    pygame.quit()
PY
