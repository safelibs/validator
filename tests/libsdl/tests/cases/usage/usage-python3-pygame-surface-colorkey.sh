#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-colorkey
# @title: pygame surface color key
# @description: Exercises pygame surface color key through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-colorkey"
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
    surface = pygame.Surface((4, 4))
    surface.set_colorkey((1, 2, 3))
    assert surface.get_colorkey()[:3] == (1, 2, 3)
    print(surface.get_colorkey())
finally:
    pygame.quit()
PY
