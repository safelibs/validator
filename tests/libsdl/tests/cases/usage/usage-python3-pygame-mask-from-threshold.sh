#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-from-threshold
# @title: pygame mask from threshold
# @description: Exercises pygame mask from threshold through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-from-threshold"
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
    surface = pygame.Surface((4, 4))
    surface.fill((0, 0, 0))
    surface.set_at((1, 1), (255, 0, 0))
    mask = pygame.mask.from_threshold(surface, (255, 0, 0), (1, 1, 1, 255))
    assert mask.count() == 1
    print(mask.count())
finally:
    pygame.quit()
PY
