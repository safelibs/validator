#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-chop
# @title: Pygame transform chop
# @description: Removes a vertical strip from a surface with pygame.transform.chop and verifies the resulting surface dimensions.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-chop"
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
    surface.fill((40, 60, 80))
    # pygame.transform.chop removes the given rect from the surface, so both
    # the rect's columns and rows disappear. Rect(4,4,8,8) drops an 8-wide
    # column and an 8-tall row, leaving 24x24.
    chopped = pygame.transform.chop(surface, pygame.Rect(4, 4, 8, 8))
    assert chopped.get_size() == (24, 24), chopped.get_size()
    # Pixel data should still be the uniform fill color.
    px = chopped.get_at((0, 0))
    assert (px.r, px.g, px.b) == (40, 60, 80)
    print("chop", chopped.get_size(), px)
finally:
    pygame.quit()
PY
