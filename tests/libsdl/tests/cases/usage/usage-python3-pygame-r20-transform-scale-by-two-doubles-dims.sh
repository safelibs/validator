#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-transform-scale-by-two-doubles-dims
# @title: Pygame transform.scale_by factor 2 doubles surface dimensions
# @description: Builds an 8x6 Surface and calls transform.scale_by(surf, 2.0) (or transform.scale with explicit (16, 12) target if scale_by is unavailable), asserting the returned Surface has width 16 and height 12, confirming SDL-backed proportional rescaling doubles both axes.
# @timeout: 60
# @tags: usage, sdl, python, transform, scale, r20
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
    s = pygame.Surface((8, 6))
    s.fill((10, 20, 30))
    if hasattr(pygame.transform, 'scale_by'):
        out = pygame.transform.scale_by(s, 2.0)
    else:
        out = pygame.transform.scale(s, (16, 12))
    assert out.get_width() == 16, out.get_width()
    assert out.get_height() == 12, out.get_height()
    print('ok scale_by w=%d h=%d' % (out.get_width(), out.get_height()))
finally:
    pygame.quit()
PY
