#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-clip
# @title: Pygame rect clip
# @description: Intersects two Pygame rectangles and verifies the clipped rectangle dimensions.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-clip"
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
    first = pygame.Rect(0, 0, 6, 6)
    second = pygame.Rect(3, 2, 6, 6)
    clipped = first.clip(second)
    assert clipped.size == (3, 4)
    print("clip", clipped.size)
finally:
    pygame.quit()
PY
