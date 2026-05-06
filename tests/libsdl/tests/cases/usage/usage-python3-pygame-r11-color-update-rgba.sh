#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-color-update-rgba
# @title: Pygame Color.update mutates RGBA components in place
# @description: Calls Color.update with explicit r/g/b/a values and verifies the same Color instance now reports the new tuple via iteration.
# @timeout: 120
# @tags: usage, sdl, python, color
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
    c = pygame.Color(0, 0, 0)
    cid = id(c)
    c.update(255, 128, 64, 32)
    assert tuple(c) == (255, 128, 64, 32), tuple(c)
    assert id(c) == cid, "Color.update should mutate in place"
finally:
    pygame.quit()
PY
