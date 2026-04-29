#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-arc
# @title: pygame draw arc
# @description: Exercises pygame draw arc through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-arc"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    surface = pygame.Surface((12, 12))
    surface.fill((0, 0, 0))
    pygame.draw.arc(surface, (255, 0, 0), pygame.Rect(1, 1, 10, 10), 0, math.pi, 1)
    painted = sum(
        1
        for y in range(surface.get_height())
        for x in range(surface.get_width())
        if surface.get_at((x, y))[:3] != (0, 0, 0)
    )
    assert painted > 0
    print(painted)
finally:
    pygame.quit()
PY
