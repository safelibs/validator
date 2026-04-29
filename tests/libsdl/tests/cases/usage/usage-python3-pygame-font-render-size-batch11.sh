#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-render-size-batch11
# @title: pygame font render size
# @description: Renders text through pygame font support and checks surface dimensions.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-font-render-size-batch11"
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
    pygame.font.init()
    font = pygame.font.Font(None, 18)
    rendered = font.render('SDL', True, (255, 255, 255))
    assert rendered.get_width() > 0 and rendered.get_height() > 0
    print('font', rendered.get_size())
finally:
    pygame.quit()
PYCASE
