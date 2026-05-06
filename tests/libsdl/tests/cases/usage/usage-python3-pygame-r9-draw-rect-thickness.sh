#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-draw-rect-thickness
# @title: Pygame draw.rect outline width
# @description: Draws a rectangle outline with width=2 and verifies the interior pixels remain background while edge pixels are the requested color.
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
    surf = pygame.Surface((30, 30))
    surf.fill((0, 0, 0))
    pygame.draw.rect(surf, (10, 220, 30), pygame.Rect(5, 5, 20, 20), width=2)
    # Top-left corner of outline is colored.
    assert tuple(surf.get_at((5, 5)))[:3] == (10, 220, 30)
    # Bottom-right corner of outline is colored.
    assert tuple(surf.get_at((24, 24)))[:3] == (10, 220, 30)
    # Interior pixel is background.
    assert tuple(surf.get_at((15, 15)))[:3] == (0, 0, 0)
    # Outside the outline is background.
    assert tuple(surf.get_at((0, 0)))[:3] == (0, 0, 0)
finally:
    pygame.quit()
PY
