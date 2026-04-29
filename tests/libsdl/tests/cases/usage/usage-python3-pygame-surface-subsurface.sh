#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-subsurface
# @title: pygame surface subsurface
# @description: Creates a pygame subsurface and verifies the subregion preserves the parent fill color and reports the requested smaller size.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-subsurface"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import os
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    surface = pygame.Surface((6, 4))
    surface.fill((10, 20, 30))
    sub = surface.subsurface(pygame.Rect(1, 1, 3, 2))
    assert sub.get_size() == (3, 2)
    assert sub.get_at((0, 0))[:3] == (10, 20, 30)
    print("subsurface", sub.get_size())
finally:
    pygame.quit()
PY
