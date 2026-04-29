#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-union
# @title: Pygame rect union
# @description: Unions two Pygame Rect values and verifies the combined rectangle dimensions.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-union"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    first = pygame.Rect(0, 0, 2, 2)
    second = pygame.Rect(2, 1, 3, 2)
    union = first.union(second)
    assert union.size == (5, 3)
    print("union", union.size)
finally:
    pygame.quit()
PY
