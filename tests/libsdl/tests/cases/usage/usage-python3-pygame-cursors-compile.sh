#!/usr/bin/env bash
# @testcase: usage-python3-pygame-cursors-compile
# @title: pygame cursors.compile
# @description: Compiles an 8x8 ASCII cursor strings tuple via pygame.cursors.compile and verifies the resulting data and mask byte tuples are non-empty and have the expected length.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-cursors-compile"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import sys
import pygame

case_id = sys.argv[1]

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

pygame.init()
try:
    data, mask = pygame.cursors.compile(strings, black="X", white=".", xor="o")
    # 8x8 / 8 bits per byte -> 8 bytes for data and 8 for mask
    assert len(data) == 8, len(data)
    assert len(mask) == 8, len(mask)
    assert all(isinstance(b, int) for b in data)
    assert any(b != 0 for b in data)
    assert all(b == 0xFF for b in mask), mask
    print("cursors-compile", len(data), len(mask))
finally:
    pygame.quit()
PYCASE
