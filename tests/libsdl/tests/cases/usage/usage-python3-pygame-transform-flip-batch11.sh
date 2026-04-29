#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-flip-batch11
# @title: pygame transform flip
# @description: Flips a pygame Surface horizontally and checks pixel placement.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-flip-batch11"
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
    surface = pygame.Surface((2, 1))
    surface.set_at((0, 0), (10, 20, 30))
    surface.set_at((1, 0), (90, 80, 70))
    out = pygame.transform.flip(surface, True, False)
    assert out.get_at((0, 0))[:3] == (90, 80, 70)
    print('flip')
finally:
    pygame.quit()
PYCASE
