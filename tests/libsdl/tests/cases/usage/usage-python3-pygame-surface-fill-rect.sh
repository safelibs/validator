#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-fill-rect
# @title: pygame surface fill rect
# @description: Fills a clipped rectangle on a pygame surface and verifies both the returned filled area and painted pixel color.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-fill-rect"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    surface = pygame.Surface((4, 3))
    filled = surface.fill((12, 34, 56), pygame.Rect(1, 1, 2, 1))
    assert filled.topleft == (1, 1) and filled.size == (2, 1)
    assert surface.get_at((1, 1))[:3] == (12, 34, 56)
    print(filled)
finally:
    pygame.quit()
PYCASE
