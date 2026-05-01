#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-circle-quadrants
# @title: pygame.draw.circle quadrant flags
# @description: Draws a single quadrant of a circle using the draw_top_right keyword on pygame.draw.circle and confirms pixels in the targeted quadrant are colored while the opposite quadrant remains background.
# @timeout: 120
# @tags: usage, draw
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-draw-circle-quadrants"

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    surf = pygame.Surface((40, 40))
    surf.fill((0, 0, 0))
    center = (20, 20)
    radius = 15
    pygame.draw.circle(surf, (255, 255, 255), center, radius,
                       width=0, draw_top_right=True)
    # A pixel offset into top-right should be filled
    tr = surf.get_at((28, 12))[:3]
    assert tr == (255, 255, 255), tr
    # Bottom-left should be untouched
    bl = surf.get_at((12, 28))[:3]
    assert bl == (0, 0, 0), bl
    # Top-left likewise untouched (only top-right requested)
    tl = surf.get_at((12, 12))[:3]
    assert tl == (0, 0, 0), tl
    print("quadrant", tr, bl, tl)
finally:
    pygame.quit()
PY
