#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-lines-open
# @title: Pygame draw lines open polyline
# @description: Draws an open multi-segment polyline with pygame.draw.lines (closed=False) and confirms intermediate edges are colored while the implicit closing edge is left untouched.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-lines-open"
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
    color = (10, 200, 30)
    points = [(2, 2), (29, 2), (29, 29), (2, 29)]
    # closed=False: draw only the three explicit segments, not the closing edge.
    pygame.draw.lines(surface, color, False, points, 1)
    top = surface.get_at((15, 2))
    right = surface.get_at((29, 15))
    bottom = surface.get_at((15, 29))
    # The implicit closing edge from (2,29) to (2,2) must remain unset.
    closing = surface.get_at((2, 15))
    for px in (top, right, bottom):
        assert (px.r, px.g, px.b) == color, px
    assert (closing.r, closing.g, closing.b) == (0, 0, 0), closing
    print("open", top, right, bottom, closing)
finally:
    pygame.quit()
PY
