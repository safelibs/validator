#!/usr/bin/env bash
# @testcase: usage-python3-pygame-subsurface-size
# @title: pygame subsurface size
# @description: Exercises pygame subsurface size through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-subsurface-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    surface = pygame.Surface((8, 6))
    sub = surface.subsurface(pygame.Rect(2, 1, 3, 2))
    assert sub.get_size() == (3, 2)
    print(sub.get_size())
finally:
    pygame.quit()
PY
