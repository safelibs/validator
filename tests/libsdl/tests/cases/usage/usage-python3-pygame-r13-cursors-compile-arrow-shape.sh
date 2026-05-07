#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-cursors-compile-arrow-shape
# @title: Pygame cursors.compile encodes an 8x8 ASCII cursor into matching mask bytes
# @description: Calls pygame.cursors.compile on an 8x8 ASCII cursor with both 'X' and '.' glyph rows, and asserts the returned data and mask sequences each contain exactly 8 byte entries (one per row of the 8-pixel-tall cursor).
# @timeout: 60
# @tags: usage, sdl, python, cursors
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
    strings = (
        "XXXXXXXX",
        "X......X",
        "X.XXXX.X",
        "X.X..X.X",
        "X.X..X.X",
        "X.XXXX.X",
        "X......X",
        "XXXXXXXX",
    )
    data, mask = pygame.cursors.compile(strings, black="X", white=".", xor="o")
    assert len(data) == 8, len(data)
    assert len(mask) == 8, len(mask)
    # The all-X first and last rows are fully opaque mask bytes (0xFF).
    assert mask[0] == 0xFF, hex(mask[0])
    assert mask[-1] == 0xFF, hex(mask[-1])
finally:
    pygame.quit()
PY
