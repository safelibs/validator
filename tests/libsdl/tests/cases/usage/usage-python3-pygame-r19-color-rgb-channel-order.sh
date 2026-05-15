#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-color-rgb-channel-order
# @title: Pygame Color exposes r/g/b/a attributes in the expected channel order
# @description: Constructs pygame.Color(10,20,30,40) and asserts the .r, .g, .b, .a attributes are exactly 10, 20, 30, 40 respectively, pinning the documented channel-attribute order on Ubuntu 24.04 pygame.
# @timeout: 60
# @tags: usage, sdl, python, color, channels, r19
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
    c = pygame.Color(10, 20, 30, 40)
    assert c.r == 10, c.r
    assert c.g == 20, c.g
    assert c.b == 30, c.b
    assert c.a == 40, c.a
finally:
    pygame.quit()
PY
