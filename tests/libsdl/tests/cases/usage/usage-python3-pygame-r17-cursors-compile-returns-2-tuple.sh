#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-cursors-compile-returns-2-tuple
# @title: Pygame cursors.compile on a small bitmap returns a 2-tuple of bytes
# @description: Calls pygame.cursors.compile on a small uniform-width string cursor and asserts the return is a tuple of length 2, pinning the documented (data, mask) return shape.
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
        "X......X",
        "X......X",
        "X......X",
        "X......X",
        "X......X",
        "XXXXXXXX",
    )
    result = pygame.cursors.compile(strings, black='X', white='.', xor='o')
    assert isinstance(result, tuple), type(result)
    assert len(result) == 2, len(result)
finally:
    pygame.quit()
PY
