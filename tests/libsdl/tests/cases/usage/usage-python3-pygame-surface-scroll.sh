#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-scroll
# @title: Pygame surface scroll
# @description: Scrolls a Pygame surface and verifies a previously painted pixel moves to the expected location.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-scroll"
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
    surface = pygame.Surface((6, 4))
    surface.fill((0, 0, 0))
    surface.set_at((1, 1), (255, 0, 0))
    surface.scroll(dx=2, dy=1)
    assert surface.get_at((3, 2)).r == 255
    print("scroll", surface.get_at((3, 2)))
finally:
    pygame.quit()
PY
