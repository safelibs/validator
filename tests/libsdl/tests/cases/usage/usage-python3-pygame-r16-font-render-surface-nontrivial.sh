#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-font-render-surface-nontrivial
# @title: Pygame font.Font(None, 14).render("Ab") returns a Surface with positive area
# @description: Loads the default font at size 14, renders "Ab" with antialiasing off and color (255, 255, 255), and asserts the resulting Surface get_size() reports both width and height strictly greater than zero.
# @timeout: 120
# @tags: usage, sdl, python, font, render
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
    pygame.font.init()
    font = pygame.font.Font(None, 14)
    surf = font.render('Ab', False, (255, 255, 255))
    w, h = surf.get_size()
    assert w > 0 and h > 0, (w, h)
finally:
    pygame.quit()
PY
