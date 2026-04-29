#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surfarray
# @title: Pygame surfarray view
# @description: Reads surface pixel data through Pygame surfarray and checks array shape.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surfarray"
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
    surface = pygame.Surface((4, 3))
    array = pygame.surfarray.array3d(surface)
    assert array.shape[:2] == (4, 3)
    print("array", array.shape)
finally:
    pygame.quit()
PY
