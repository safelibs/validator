#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-clip-fill
# @title: pygame surface clip fill
# @description: Sets a pygame surface clip rectangle, fills through that clip, and verifies only pixels inside the clip region change color.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-clip-fill"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    surface = pygame.Surface((2, 2), pygame.SRCALPHA)
    surface.fill((255, 0, 0, 255))
    surface.set_clip(pygame.Rect(1, 0, 1, 2))
    surface.fill((0, 255, 0, 255))
    assert surface.get_clip() == pygame.Rect(1, 0, 1, 2)
    assert surface.get_at((1, 0))[:3] == (0, 255, 0)
    assert surface.get_at((0, 0))[:3] == (255, 0, 0)
    print(surface.get_clip())
finally:
    pygame.quit()
PYCASE
