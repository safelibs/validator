#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-draw-aacircle-bounding-box-set
# @title: Pygame draw.circle returns a dirty Rect with positive width and height
# @description: Calls pygame.draw.circle on a black 32x32 Surface and asserts the returned dirty Rect has both width > 0 and height > 0 and intersects the surface area, pinning the SDL-backed circle drawing's dirty-rect reporting contract.
# @timeout: 60
# @tags: usage, sdl, python, draw, circle, dirty-rect, r21
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
    surf = pygame.Surface((32, 32))
    surf.fill((0, 0, 0))
    r = pygame.draw.circle(surf, (255, 255, 255), (16, 16), 6)
    assert r.width > 0 and r.height > 0, r
    surface_rect = surf.get_rect()
    assert surface_rect.colliderect(r), (r, surface_rect)
finally:
    pygame.quit()
PY
