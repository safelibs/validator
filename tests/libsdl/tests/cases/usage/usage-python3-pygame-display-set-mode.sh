#!/usr/bin/env bash
# @testcase: usage-python3-pygame-display-set-mode
# @title: Pygame display set mode
# @description: Creates a dummy SDL display surface through Pygame and verifies the requested window dimensions.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-display-set-mode"
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
    screen = pygame.display.set_mode((8, 6))
    assert screen.get_size() == (8, 6)
    print("display", screen.get_size())
finally:
    pygame.quit()
PY
