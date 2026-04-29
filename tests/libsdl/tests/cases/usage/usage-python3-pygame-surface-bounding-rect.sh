#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-bounding-rect
# @title: pygame surface bounding rect
# @description: Exercises pygame surface bounding rect through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-bounding-rect"
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
    surface = pygame.Surface((4, 4), pygame.SRCALPHA)
    surface.fill((0, 0, 0, 0))
    surface.set_at((2, 1), (255, 0, 0, 255))
    rect = surface.get_bounding_rect()
    assert rect.topleft == (2, 1) and rect.size == (1, 1)
    print(rect)
finally:
    pygame.quit()
PYCASE
