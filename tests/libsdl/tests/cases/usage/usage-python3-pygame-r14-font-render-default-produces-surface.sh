#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-font-render-default-produces-surface
# @title: Pygame font.Font(None, size).render returns a positively-sized Surface
# @description: Initialises pygame.font, constructs Font(None, 18), renders the text 'r14' with antialias=True onto a black background, and asserts the returned Surface has positive width and height.
# @timeout: 120
# @tags: usage, sdl, python, font
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
import pygame.font

pygame.init()
pygame.font.init()
try:
    font = pygame.font.Font(None, 18)
    surf = font.render("r14", True, (255, 255, 255), (0, 0, 0))
    w, h = surf.get_size()
    assert w > 0, w
    assert h > 0, h
finally:
    pygame.font.quit()
    pygame.quit()
PY
