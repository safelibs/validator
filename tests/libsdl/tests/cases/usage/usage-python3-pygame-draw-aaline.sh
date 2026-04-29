#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-aaline
# @title: pygame draw aaline
# @description: Exercises pygame draw aaline through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-aaline"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    surface = pygame.Surface((12, 12))
    surface.fill((0, 0, 0))
    pygame.draw.aaline(surface, (255, 255, 255), (1, 1), (10, 8))
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
PYCASE
