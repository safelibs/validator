#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-rect-rgba
# @title: Pygame draw rect with RGBA color
# @description: Draws a filled rectangle on an SRCALPHA Pygame surface using a 4-tuple RGBA color and verifies the alpha channel is preserved at the painted pixel.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-rect-rgba"
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
    surface = pygame.Surface((8, 8), pygame.SRCALPHA)
    pygame.draw.rect(surface, (255, 0, 0, 128), pygame.Rect(1, 1, 4, 4))
    pixel = tuple(surface.get_at((2, 2)))
    assert pixel == (255, 0, 0, 128), pixel
    untouched = tuple(surface.get_at((7, 7)))
    assert untouched[3] == 0, untouched
    print("rgba", pixel, untouched)
finally:
    pygame.quit()
PY
