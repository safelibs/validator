#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-from-surface-density
# @title: Pygame mask from_surface density
# @description: Builds a checkerboard surface, calls pygame.mask.from_surface(), and confirms the mask reports exactly half of the pixels as set.
# @timeout: 120
# @tags: usage, mask, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-from-surface-density"
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
    width, height = 8, 8
    surf = pygame.Surface((width, height), pygame.SRCALPHA)
    surf.fill((0, 0, 0, 0))
    set_pixels = 0
    for y in range(height):
        for x in range(width):
            if (x + y) % 2 == 0:
                surf.set_at((x, y), (255, 255, 255, 255))
                set_pixels += 1
    mask = pygame.mask.from_surface(surf)
    assert mask.get_size() == (width, height)
    assert mask.count() == set_pixels
    assert mask.count() == width * height // 2
    assert mask.get_at((0, 0)) == 1
    assert mask.get_at((1, 0)) == 0
    print("mask", mask.count())
finally:
    pygame.quit()
PY
