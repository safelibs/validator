#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-flip-vertical
# @title: Pygame transform flip vertical
# @description: Flips a Pygame surface vertically via pygame.transform.flip(False, True) and confirms the top and bottom rows are swapped.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-flip-vertical"
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
    surface = pygame.Surface((4, 3))
    surface.set_at((0, 0), (255, 0, 0))
    surface.set_at((0, 2), (0, 0, 255))
    flipped = pygame.transform.flip(surface, False, True)
    assert flipped.get_size() == (4, 3)
    top = tuple(flipped.get_at((0, 0)))[:3]
    bottom = tuple(flipped.get_at((0, 2)))[:3]
    assert top == (0, 0, 255), top
    assert bottom == (255, 0, 0), bottom
    print("flip-v", top, bottom)
finally:
    pygame.quit()
PY
