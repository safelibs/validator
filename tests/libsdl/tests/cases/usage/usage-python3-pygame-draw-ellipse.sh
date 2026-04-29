#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-ellipse
# @title: Pygame draws ellipse
# @description: Draws an ellipse on a headless Pygame surface and verifies a painted pixel along the outline.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-ellipse"
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
    surface = pygame.Surface((12, 10))
    pygame.draw.ellipse(surface, (255, 0, 0), pygame.Rect(1, 1, 10, 8))
    assert surface.get_at((6, 1)).r == 255
    print("ellipse", surface.get_at((6, 1)))
finally:
    pygame.quit()
PY
