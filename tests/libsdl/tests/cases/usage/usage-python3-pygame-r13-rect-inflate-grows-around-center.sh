#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-rect-inflate-grows-around-center
# @title: Pygame Rect.inflate grows symmetrically around the original center
# @description: Inflates a 10x10 Rect by (4,6), asserting the resulting size grew by the requested amounts and the center stayed the same as the source rectangle.
# @timeout: 60
# @tags: usage, sdl, python, rect
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
    r = pygame.Rect(20, 30, 10, 10)
    expected_center = r.center
    bigger = r.inflate(4, 6)
    assert bigger.size == (14, 16), bigger.size
    assert bigger.center == expected_center, (bigger.center, expected_center)
    # Original rectangle unmodified by the non-_ip variant.
    assert r.size == (10, 10)
finally:
    pygame.quit()
PY
