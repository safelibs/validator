#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-rect-collidelist-returns-index
# @title: Pygame Rect.collidelist returns the index of the first colliding rect
# @description: Builds a probe Rect and a list of three candidate Rects where only the second overlaps the probe, calls collidelist, and asserts the returned index is exactly 1, pinning the first-match-wins semantics of the SDL-backed Rect collision helper.
# @timeout: 60
# @tags: usage, sdl, python, rect, collidelist, r21
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
    probe = pygame.Rect(10, 10, 5, 5)
    candidates = [
        pygame.Rect(100, 100, 5, 5),
        pygame.Rect(12, 12, 5, 5),
        pygame.Rect(200, 200, 5, 5),
    ]
    idx = probe.collidelist(candidates)
    assert idx == 1, idx
finally:
    pygame.quit()
PY
