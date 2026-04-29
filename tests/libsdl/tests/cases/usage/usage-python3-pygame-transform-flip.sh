#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-flip
# @title: Pygame flips surface
# @description: Flips a Pygame surface and verifies the output dimensions remain stable.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-flip"
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
    flipped = pygame.transform.flip(surface, True, False)
    assert flipped.get_size() == (6, 4)
    print("flip", flipped.get_size())
finally:
    pygame.quit()
PY
