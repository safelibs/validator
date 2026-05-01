#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-move-translation
# @title: Pygame rect move translation
# @description: Translates a Pygame Rect via move() and confirms the original rect is unchanged while the result is shifted.
# @timeout: 120
# @tags: usage, rect, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-move-translation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    base = pygame.Rect(5, 7, 20, 10)
    moved = base.move(3, -2)
    assert base.topleft == (5, 7)
    assert moved.topleft == (8, 5)
    assert moved.size == base.size
    moved_neg = base.move(-100, -100)
    assert moved_neg.topleft == (-95, -93)
    print("move", moved.topleft, moved_neg.topleft)
finally:
    pygame.quit()
PY
