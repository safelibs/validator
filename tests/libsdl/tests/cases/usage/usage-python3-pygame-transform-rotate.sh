#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-rotate
# @title: Pygame rotates surface
# @description: Rotates a Pygame surface and checks the output dimensions.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-rotate"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    surface = pygame.Surface((6, 4))
    rotated = pygame.transform.rotate(surface, 90)
    assert rotated.get_size() == (4, 6)
    print("rotate", rotated.get_size())
finally:
    pygame.quit()
PY
