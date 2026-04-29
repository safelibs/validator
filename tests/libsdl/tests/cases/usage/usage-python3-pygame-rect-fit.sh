#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-fit
# @title: pygame rect fit
# @description: Exercises pygame rect fit through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-fit"
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
    inner = pygame.Rect(0, 0, 20, 10)
    outer = pygame.Rect(0, 0, 5, 5)
    fitted = inner.fit(outer)
    assert fitted.width == 5 and fitted.height == 2
    print(fitted.size)
finally:
    pygame.quit()
PYCASE
