#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-collision
# @title: Pygame rect collision
# @description: Uses Pygame Rect collision helpers with the SDL video driver in dummy mode.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-collision"
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
    a = pygame.Rect(0, 0, 10, 10)
    b = pygame.Rect(5, 5, 3, 3)
    assert a.colliderect(b)
    print("collision", a.clip(b).size)
finally:
    pygame.quit()
PY
