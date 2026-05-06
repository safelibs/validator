#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-mask-scale-double
# @title: Pygame Mask.scale doubles dimensions and bit count
# @description: Builds a fully-filled 4x4 Mask, scales it to 8x8 with Mask.scale, and verifies both the new size and that all 64 bits remain set.
# @timeout: 120
# @tags: usage, sdl, python, mask
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
    m = pygame.mask.Mask((4, 4), fill=True)
    assert m.count() == 16
    scaled = m.scale((8, 8))
    assert scaled.get_size() == (8, 8), scaled.get_size()
    assert scaled.count() == 64, scaled.count()
finally:
    pygame.quit()
PY
