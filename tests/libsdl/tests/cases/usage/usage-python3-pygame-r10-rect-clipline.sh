#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-rect-clipline
# @title: Pygame Rect.clipline trims line to rect bounds
# @description: Clips a line that crosses a Rect against the Rect bounds and verifies the returned endpoints sit on the Rect's edges.
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
    rect = pygame.Rect(10, 10, 20, 20)
    # Line passes diagonally through the rect from (0,0) to (40,40).
    clipped = rect.clipline(0, 0, 40, 40)
    assert clipped, "expected non-empty clipline result"
    (x1, y1), (x2, y2) = clipped
    # Endpoints must lie on the rect's edges.
    assert (x1, y1) == (10, 10)
    assert (x2, y2) == (29, 29)

    # Line entirely outside returns empty tuple.
    outside = rect.clipline(0, 0, 5, 5)
    assert outside == ()
finally:
    pygame.quit()
PY
