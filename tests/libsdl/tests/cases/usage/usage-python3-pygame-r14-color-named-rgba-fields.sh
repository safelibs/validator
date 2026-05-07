#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-color-named-rgba-fields
# @title: Pygame Color('red') exposes the canonical RGBA tuple (255, 0, 0, 255)
# @description: Constructs pygame.Color('red') and asserts the .r/.g/.b/.a fields are 255/0/0/255 respectively, and that tuple(color) equals (255, 0, 0, 255).
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
    c = pygame.Color('red')
    assert (c.r, c.g, c.b, c.a) == (255, 0, 0, 255), (c.r, c.g, c.b, c.a)
    assert tuple(c) == (255, 0, 0, 255), tuple(c)
finally:
    pygame.quit()
PY
