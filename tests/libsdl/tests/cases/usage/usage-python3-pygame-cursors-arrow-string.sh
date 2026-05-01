#!/usr/bin/env bash
# @testcase: usage-python3-pygame-cursors-arrow-string
# @title: Pygame cursors arrow strings
# @description: Validates pygame.cursors.arrow shape and mask string tuples have matching dimensions and are compilable into a cursor data tuple.
# @timeout: 120
# @tags: usage, cursors, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-cursors-arrow-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame
import pygame.cursors as cursors

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    arrow = cursors.arrow
    assert isinstance(arrow, tuple)
    assert len(arrow) == 24
    width = len(arrow[0])
    assert width % 8 == 0
    for line in arrow:
        assert len(line) == width
        assert set(line).issubset(set("Xox. "))
    data, mask = cursors.compile(arrow, black="X", white=".", xor="o")
    expected = (width // 8) * 24
    assert len(data) == expected
    assert len(mask) == expected
    print("cursor", width, len(data))
finally:
    pygame.quit()
PY
