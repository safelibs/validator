#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-font-sysfont-fallback-returns-font
# @title: Pygame font.SysFont falls back to default and returns a Font object
# @description: Calls pygame.font.SysFont with a deliberately bogus family name and asserts the returned object is an instance of pygame.font.Font — exercising the system-font fallback path bundled with SDL_ttf.
# @timeout: 60
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
    fnt = pygame.font.SysFont("no-such-family-12345-r17", 14)
    assert isinstance(fnt, pygame.font.Font), type(fnt)
finally:
    pygame.font.quit()
    pygame.quit()
PY
