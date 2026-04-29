#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-polygon
# @title: Pygame draws polygon
# @description: Draws a filled polygon on a headless Pygame surface and verifies an interior pixel is colored.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-polygon"
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
    surface = pygame.Surface((12, 12))
    pygame.draw.polygon(surface, (0, 255, 0), [(1, 10), (6, 1), (10, 10)])
    assert surface.get_at((6, 5)).g == 255
    print("polygon", surface.get_at((6, 5)))
finally:
    pygame.quit()
PY
