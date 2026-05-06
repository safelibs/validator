#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-draw-line-pixels
# @title: Pygame draw.line endpoints colored
# @description: Draws a horizontal line via pygame.draw.line and verifies the start, middle, and end pixels carry the requested color.
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
    surf = pygame.Surface((20, 5))
    surf.fill((0, 0, 0))
    pygame.draw.line(surf, (255, 128, 64), (2, 2), (17, 2))
    for x in (2, 9, 17):
        c = tuple(surf.get_at((x, 2)))[:3]
        assert c == (255, 128, 64), (x, c)
    # A pixel off the line stays black.
    assert tuple(surf.get_at((10, 4)))[:3] == (0, 0, 0)
finally:
    pygame.quit()
PY
