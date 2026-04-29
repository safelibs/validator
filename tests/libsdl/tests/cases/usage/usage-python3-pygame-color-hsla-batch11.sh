#!/usr/bin/env bash
# @testcase: usage-python3-pygame-color-hsla-batch11
# @title: pygame color HSLA
# @description: Reads HSLA components from a pygame Color value.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-color-hsla-batch11"
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
    color = pygame.Color(255, 0, 0)
    h, s, l, a = color.hsla
    assert int(h) == 0 and int(s) == 100 and int(l) == 50 and int(a) == 100
    print('hsla', color.hsla)
finally:
    pygame.quit()
PYCASE
