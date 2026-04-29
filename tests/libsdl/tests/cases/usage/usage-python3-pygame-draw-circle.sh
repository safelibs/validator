#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-circle
# @title: Pygame draws circle
# @description: Draws a circle on a Pygame surface and checks a colored pixel on the outline.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-circle"
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
    surface = pygame.Surface((10, 10))
    pygame.draw.circle(surface, (0, 255, 0), (5, 5), 3)
    assert surface.get_at((5, 2)).g == 255
    print("circle", surface.get_at((5, 2)))
finally:
    pygame.quit()
PY
