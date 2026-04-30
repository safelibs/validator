#!/usr/bin/env bash
# @testcase: usage-python3-pygame-color-hex-parse
# @title: Pygame Color hex parsing
# @description: Constructs a pygame.Color from a hex string ("#FF0000") and confirms the resulting RGBA channel values.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-color-hex-parse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    red = pygame.Color("#FF0000")
    assert (red.r, red.g, red.b) == (255, 0, 0), (red.r, red.g, red.b)
    blue = pygame.Color("#0000FF")
    assert (blue.r, blue.g, blue.b) == (0, 0, 255), (blue.r, blue.g, blue.b)
    print("hex", tuple(red), tuple(blue))
finally:
    pygame.quit()
PY
