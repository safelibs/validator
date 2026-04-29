#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-count
# @title: Pygame mask count
# @description: Creates a Pygame mask from a surface and verifies the number of opaque pixels in the mask.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-count"
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
    surface = pygame.Surface((6, 6), pygame.SRCALPHA)
    pygame.draw.rect(surface, (255, 255, 255, 255), pygame.Rect(1, 1, 3, 2))
    mask = pygame.mask.from_surface(surface)
    assert mask.count() == 6
    print("mask", mask.count())
finally:
    pygame.quit()
PY
