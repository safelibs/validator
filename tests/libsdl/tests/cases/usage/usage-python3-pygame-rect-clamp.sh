#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-clamp
# @title: pygame rectangle clamp
# @description: Exercises pygame rectangle clamp through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-clamp"
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
    inner = pygame.Rect(8, 8, 4, 4)
    outer = pygame.Rect(0, 0, 10, 10)
    clamped = inner.clamp(outer)
    assert outer.contains(clamped)
    print(clamped.topleft)
finally:
    pygame.quit()
PY
