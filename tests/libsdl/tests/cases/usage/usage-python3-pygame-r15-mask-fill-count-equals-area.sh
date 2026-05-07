#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-mask-fill-count-equals-area
# @title: Pygame Mask.fill sets every bit so count equals width * height
# @description: Constructs a pygame.Mask of size (7, 5), calls .fill(), and asserts .count() returns 35 (== 7 * 5), confirming all bits are set after fill.
# @timeout: 60
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
    m = pygame.mask.Mask((7, 5))
    assert m.count() == 0, m.count()
    m.fill()
    assert m.count() == 35, m.count()
    assert m.get_size() == (7, 5), m.get_size()
finally:
    pygame.quit()
PY
