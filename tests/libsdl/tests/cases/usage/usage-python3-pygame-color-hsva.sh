#!/usr/bin/env bash
# @testcase: usage-python3-pygame-color-hsva
# @title: pygame color HSVA
# @description: Exercises pygame color hsva through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-color-hsva"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    color = pygame.Color(0, 0, 0)
    color.hsva = (120, 100, 100, 100)
    assert color.g == 255 and color.r == 0 and color.b == 0
    print(color.g)
finally:
    pygame.quit()
PYCASE
