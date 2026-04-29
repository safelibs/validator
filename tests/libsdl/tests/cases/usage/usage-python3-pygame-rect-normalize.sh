#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-normalize
# @title: pygame rect normalize
# @description: Exercises pygame rect normalize through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-normalize"
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
    rect = pygame.Rect(5, 5, -3, -2)
    rect.normalize()
    assert rect.topleft == (2, 3) and rect.size == (3, 2)
    print(rect)
finally:
    pygame.quit()
PYCASE
