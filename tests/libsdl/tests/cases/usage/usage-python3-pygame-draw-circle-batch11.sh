#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-circle-batch11
# @title: pygame draw circle
# @description: Draws a circle on a pygame Surface and checks the affected rectangle.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-circle-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    surface = pygame.Surface((7, 7))
    rect = pygame.draw.circle(surface, (200, 10, 20), (3, 3), 2)
    assert rect.width >= 4 and rect.height >= 4
    assert surface.get_at((3, 3))[:3] == (200, 10, 20)
    print('circle', rect)
finally:
    pygame.quit()
PYCASE
