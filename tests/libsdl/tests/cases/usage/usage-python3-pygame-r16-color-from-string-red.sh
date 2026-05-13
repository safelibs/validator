#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-color-from-string-red
# @title: Pygame Color constructed from the named string "red" reports RGB (255, 0, 0)
# @description: Constructs pygame.Color("red") and asserts the resulting Color's (r, g, b) tuple equals (255, 0, 0) — pinning the named-color lookup path on Ubuntu 24.04 python3-pygame.
# @timeout: 60
# @tags: usage, sdl, python, color, named
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
    assert (c.r, c.g, c.b) == (255, 0, 0), (c.r, c.g, c.b)
finally:
    pygame.quit()
PY
