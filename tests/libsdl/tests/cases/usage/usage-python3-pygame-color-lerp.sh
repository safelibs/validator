#!/usr/bin/env bash
# @testcase: usage-python3-pygame-color-lerp
# @title: Pygame color lerp
# @description: Interpolates a Pygame color and verifies the resulting channel value.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-color-lerp"
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
    color = pygame.Color(0, 0, 0).lerp((255, 0, 0), 0.5)
    assert color.r > 0
    print("color", color.r)
finally:
    pygame.quit()
PY
