#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-surface-blit-area-source-subregion
# @title: Pygame Surface.blit with source area selects only the requested subregion
# @description: Fills two halves of an 8x4 source Surface (left red, right blue), blits onto a black destination with area=Rect(0,0,4,4) (left half only), and asserts the destination contains red and not blue, pinning the area-based subregion blit contract.
# @timeout: 60
# @tags: usage, sdl, python, surface, blit, area, r19
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
    src = pygame.Surface((8, 4))
    for y in range(4):
        for x in range(4):
            src.set_at((x, y), (255, 0, 0))
        for x in range(4, 8):
            src.set_at((x, y), (0, 0, 255))
    dst = pygame.Surface((8, 4))
    dst.fill((0, 0, 0))
    dst.blit(src, (0, 0), area=pygame.Rect(0, 0, 4, 4))
    # Left half should be red, right half should remain black (not blue)
    lr = dst.get_at((0, 0))[:3]
    rr = dst.get_at((6, 2))[:3]
    assert lr == (255, 0, 0), lr
    assert rr == (0, 0, 0), rr
finally:
    pygame.quit()
PY
