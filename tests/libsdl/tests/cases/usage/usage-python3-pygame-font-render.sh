#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-render
# @title: Pygame font render
# @description: Renders text with the default Pygame font and verifies the resulting surface dimensions.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-font-render"
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
    pygame.font.init()
    font = pygame.font.Font(None, 24)
    surface = font.render("hello", True, (255, 255, 255))
    assert surface.get_width() > 0 and surface.get_height() > 0
    print("font", surface.get_size())
finally:
    pygame.quit()
PY
