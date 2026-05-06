#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-surface-blit-area
# @title: Pygame Surface.blit area sub-rectangle
# @description: Blits a sub-rect of a source surface onto a destination and verifies pixels at the destination match the source's sub-rect contents.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import pygame
pygame.init()
try:
    src = pygame.Surface((8, 8))
    src.fill((20, 30, 40))
    src.fill((200, 100, 50), pygame.Rect(2, 2, 4, 4))
    dst = pygame.Surface((10, 10))
    dst.fill((0, 0, 0))
    # Blit only the colored sub-rect onto dst at (1, 1).
    dst.blit(src, (1, 1), area=pygame.Rect(2, 2, 4, 4))
    assert tuple(dst.get_at((1, 1)))[:3] == (200, 100, 50)
    assert tuple(dst.get_at((4, 4)))[:3] == (200, 100, 50)
    # Pixel just outside the blit destination remains black.
    assert tuple(dst.get_at((0, 0)))[:3] == (0, 0, 0)
    assert tuple(dst.get_at((5, 5)))[:3] == (0, 0, 0)
finally:
    pygame.quit()
PY
