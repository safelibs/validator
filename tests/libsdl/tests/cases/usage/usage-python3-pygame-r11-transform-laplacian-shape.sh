#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-transform-laplacian-shape
# @title: Pygame transform.laplacian preserves surface geometry
# @description: Calls transform.laplacian on a 16x12 uniform-fill surface and verifies the result keeps the same dimensions while collapsing the interior to zero gradient.
# @timeout: 120
# @tags: usage, sdl, python, transform
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame

pygame.init()
try:
    src = pygame.Surface((16, 12))
    src.fill((128, 128, 128))
    lap = pygame.transform.laplacian(src)
    assert lap.get_size() == (16, 12), lap.get_size()
    # A uniform fill has no edges, so the centre pixel must be zero.
    cx, cy = 8, 6
    r, g, b, _ = lap.get_at((cx, cy))
    assert (r, g, b) == (0, 0, 0), (r, g, b)
finally:
    pygame.quit()
PY
