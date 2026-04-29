#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-size
# @title: pygame font size
# @description: Exercises pygame font size through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-font-size"
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
    font = pygame.font.Font(None, 24)
    width, height = font.size('validator')
    assert width > 0 and height > 0
    print(width, height)
finally:
    pygame.quit()
PYCASE
