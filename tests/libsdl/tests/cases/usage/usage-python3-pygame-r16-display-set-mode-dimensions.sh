#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-display-set-mode-dimensions
# @title: Pygame display.set_mode under Xvfb returns a Surface with requested dimensions
# @description: Calls pygame.display.set_mode((160, 120)) under xvfb-run and asserts the returned Surface reports get_size() == (160, 120) — exercising the live SDL display path rather than the dummy driver.
# @timeout: 120
# @tags: usage, sdl, python, display
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_AUDIODRIVER=dummy

validator_run_xvfb python3 - <<'PY'
import pygame

pygame.init()
try:
    surf = pygame.display.set_mode((160, 120))
    assert surf.get_size() == (160, 120), surf.get_size()
finally:
    pygame.quit()
PY
