#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-lines-polyline
# @title: Pygame draw lines polyline
# @description: Draws a multi-segment polyline with pygame.draw.lines and verifies pixels along each segment carry the requested color.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-lines-polyline"
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
    surface = pygame.Surface((32, 32))
    surface.fill((0, 0, 0))
    points = [(2, 2), (29, 2), (29, 29), (2, 29)]
    pygame.draw.lines(surface, (255, 128, 0), True, points, 1)
    # Sample one pixel from each of the four edges.
    top = surface.get_at((15, 2))
    right = surface.get_at((29, 15))
    bottom = surface.get_at((15, 29))
    left = surface.get_at((2, 15))
    for px in (top, right, bottom, left):
        assert (px.r, px.g, px.b) == (255, 128, 0), px
    # Interior should still be black.
    interior = surface.get_at((15, 15))
    assert (interior.r, interior.g, interior.b) == (0, 0, 0)
    print("polyline", top, right, bottom, left)
finally:
    pygame.quit()
PY
