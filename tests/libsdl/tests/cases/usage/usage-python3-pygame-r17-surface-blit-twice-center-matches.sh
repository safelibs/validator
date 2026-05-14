#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-surface-blit-twice-center-matches
# @title: Pygame Surface.blit applied twice yields the source colour at the centre
# @description: Blits a 4x4 coloured Surface onto a 16x16 base at the same offset twice and asserts Surface.get_at on the centre of the blitted area returns the source colour, exercising cumulative blits through SDL2.
# @timeout: 60
# @tags: usage, sdl, python, blit
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
    base = pygame.Surface((16, 16))
    base.fill((10, 10, 10))
    src = pygame.Surface((4, 4))
    src.fill((200, 50, 100))
    base.blit(src, (6, 6))
    base.blit(src, (6, 6))
    r, g, b, _ = base.get_at((8, 8))
    assert (r, g, b) == (200, 50, 100), (r, g, b)
finally:
    pygame.quit()
PY
