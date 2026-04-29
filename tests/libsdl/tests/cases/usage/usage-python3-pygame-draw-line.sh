#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-line
# @title: Pygame draws line
# @description: Draws a line on a Pygame surface and checks a colored pixel.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-line"
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
    surface = pygame.Surface((8, 8))
    pygame.draw.line(surface, (255, 0, 0), (0, 0), (7, 7), 1)
    assert surface.get_at((3, 3)).r == 255
    print("line", surface.get_at((3, 3)))
finally:
    pygame.quit()
PY
