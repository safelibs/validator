#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-surface-blits-list-applies-each
# @title: Pygame Surface.blits applies a list of (source, dest) pairs in order
# @description: Builds a 6x6 target Surface and two distinct 2x2 source Surfaces; uses Surface.blits to draw the red source at (0,0) and the green source at (4,4) in a single call, then asserts the corresponding pixels reflect each source color, pinning batched blit ordering.
# @timeout: 60
# @tags: usage, sdl, python, surface, blits, r21
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
    target = pygame.Surface((6, 6))
    target.fill((0, 0, 0))
    red = pygame.Surface((2, 2)); red.fill((200, 0, 0))
    green = pygame.Surface((2, 2)); green.fill((0, 200, 0))
    target.blits([(red, (0, 0)), (green, (4, 4))])
    pr = target.get_at((0, 0))
    pg = target.get_at((4, 4))
    assert (pr.r, pr.g, pr.b) == (200, 0, 0), pr
    assert (pg.r, pg.g, pg.b) == (0, 200, 0), pg
finally:
    pygame.quit()
PY
