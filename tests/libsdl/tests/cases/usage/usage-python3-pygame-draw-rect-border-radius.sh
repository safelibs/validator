#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-rect-border-radius
# @title: Pygame draw rect with border radius
# @description: Draws a filled rounded rectangle and verifies that the rounded corner pixel is transparent while the center pixel carries the fill color.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-rect-border-radius"
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
    surface = pygame.Surface((32, 32), pygame.SRCALPHA)
    surface.fill((0, 0, 0, 0))
    rect = pygame.Rect(0, 0, 32, 32)
    pygame.draw.rect(surface, (10, 200, 50, 255), rect, border_radius=8)
    center = surface.get_at((16, 16))
    assert (center.r, center.g, center.b, center.a) == (10, 200, 50, 255)
    # Top-left corner (0, 0) should remain transparent due to the rounded radius.
    corner = surface.get_at((0, 0))
    assert corner.a == 0, corner
    print("rounded", center, corner)
finally:
    pygame.quit()
PY
