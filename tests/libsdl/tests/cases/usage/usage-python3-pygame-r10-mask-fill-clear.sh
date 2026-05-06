#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-mask-fill-clear
# @title: Pygame Mask.fill and Mask.clear toggle every bit
# @description: Creates a mask, calls fill() and clear(), and verifies count() reaches the full size and zero respectively.
# @timeout: 120
# @tags: usage, sdl, python
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
    mask = pygame.mask.Mask((16, 12))
    assert mask.count() == 0

    mask.fill()
    assert mask.count() == 16 * 12
    # Every individual bit should also be set.
    assert mask.get_at((0, 0)) == 1
    assert mask.get_at((15, 11)) == 1

    mask.clear()
    assert mask.count() == 0
    assert mask.get_at((5, 5)) == 0
finally:
    pygame.quit()
PY
