#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-surface-premul-alpha
# @title: Pygame Surface.premul_alpha multiplies RGB channels by alpha
# @description: Fills an SRCALPHA surface with (200, 100, 50, 128), calls premul_alpha, and verifies each RGB channel is multiplied by alpha/255.
# @timeout: 120
# @tags: usage, sdl, python, surface
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
    s = pygame.Surface((2, 2), pygame.SRCALPHA)
    s.fill((200, 100, 50, 128))
    premul = s.premul_alpha()
    r, g, b, a = premul.get_at((0, 0))
    assert (r, g, b, a) == (100, 50, 25, 128), (r, g, b, a)
finally:
    pygame.quit()
PY
