#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-surface-blit-copy-pixel
# @title: Pygame Surface.blit copies a pixel from a source surface to a destination
# @description: Creates a 4x4 source filled red and a 4x4 destination filled blue, blits the source at (0,0), and asserts the destination pixel matches red while a non-overlapping region remains blue.
# @timeout: 120
# @tags: usage, sdl, python, surface, blit
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
    src = pygame.Surface((4, 4))
    src.fill((255, 0, 0))
    dst = pygame.Surface((8, 8))
    dst.fill((0, 0, 255))
    dst.blit(src, (0, 0))
    r, g, b, _ = dst.get_at((1, 1))
    assert (r, g, b) == (255, 0, 0), (r, g, b)
    r2, g2, b2, _ = dst.get_at((6, 6))
    assert (r2, g2, b2) == (0, 0, 255), (r2, g2, b2)
finally:
    pygame.quit()
PY
