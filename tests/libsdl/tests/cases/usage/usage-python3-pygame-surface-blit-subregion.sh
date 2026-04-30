#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-blit-subregion
# @title: Pygame surface blit subregion
# @description: Blits a sub-rectangle of one Pygame surface onto another using the area argument and verifies pixels inside and outside the copied region.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-blit-subregion"
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
    src = pygame.Surface((6, 6))
    src.fill((10, 20, 30))
    pygame.draw.rect(src, (200, 100, 50), pygame.Rect(2, 2, 2, 2))
    dest = pygame.Surface((6, 6))
    dest.fill((0, 0, 0))
    dest.blit(src, (0, 0), area=pygame.Rect(2, 2, 2, 2))
    inside = tuple(dest.get_at((0, 0)))[:3]
    outside = tuple(dest.get_at((5, 5)))[:3]
    assert inside == (200, 100, 50), inside
    assert outside == (0, 0, 0), outside
    print("blit-sub", inside, outside)
finally:
    pygame.quit()
PY
