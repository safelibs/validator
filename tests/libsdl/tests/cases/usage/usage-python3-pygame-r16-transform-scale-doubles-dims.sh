#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-transform-scale-doubles-dims
# @title: Pygame transform.scale 2x produces a Surface with doubled dimensions
# @description: Builds an 8x4 Surface, calls pygame.transform.scale to (16, 8), and asserts the returned Surface reports get_size() == (16, 8) — pinning the explicit-size scale path.
# @timeout: 120
# @tags: usage, sdl, python, transform, scale
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
    surf = pygame.Surface((8, 4))
    surf.fill((20, 40, 60))
    scaled = pygame.transform.scale(surf, (16, 8))
    assert scaled.get_size() == (16, 8), scaled.get_size()
finally:
    pygame.quit()
PY
