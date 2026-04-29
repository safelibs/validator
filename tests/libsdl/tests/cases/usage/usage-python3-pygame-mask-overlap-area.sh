#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-overlap-area
# @title: Pygame mask overlap area
# @description: Computes overlap area between two Pygame masks and verifies the nonzero result.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-overlap-area"
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
    first = pygame.mask.Mask((4, 4), fill=True)
    second = pygame.mask.Mask((4, 4), fill=True)
    area = first.overlap_area(second, (1, 1))
    assert area > 0
    print("area", area)
finally:
    pygame.quit()
PY
