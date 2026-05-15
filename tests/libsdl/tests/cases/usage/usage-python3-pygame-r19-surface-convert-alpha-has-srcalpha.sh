#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-surface-convert-alpha-has-srcalpha
# @title: Pygame Surface.convert_alpha returns a SRCALPHA-flagged Surface
# @description: Creates a display Surface on the dummy driver, calls convert_alpha on a freshly allocated Surface, and asserts the resulting Surface has the SRCALPHA flag bit set in get_flags, pinning the alpha-conversion contract.
# @timeout: 60
# @tags: usage, sdl, python, surface, convert-alpha, r19
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
    pygame.display.set_mode((32, 32))
    s = pygame.Surface((16, 16))
    a = s.convert_alpha()
    assert (a.get_flags() & pygame.SRCALPHA) != 0, a.get_flags()
finally:
    pygame.quit()
PY
