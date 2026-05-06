#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-color-cmy-property
# @title: Pygame Color.cmy reports CMY tuple for primary colors
# @description: Reads Color.cmy on red and white and verifies the cyan/magenta/yellow components match the printing-press complement of RGB.
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
    red = pygame.Color('red')
    assert red.cmy == (0.0, 1.0, 1.0), red.cmy

    white = pygame.Color(255, 255, 255)
    assert white.cmy == (0.0, 0.0, 0.0), white.cmy

    black = pygame.Color(0, 0, 0)
    assert black.cmy == (1.0, 1.0, 1.0), black.cmy
finally:
    pygame.quit()
PY
