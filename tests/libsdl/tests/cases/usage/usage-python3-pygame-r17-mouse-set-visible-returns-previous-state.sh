#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-mouse-set-visible-returns-previous-state
# @title: Pygame mouse.set_visible(False) returns 1 (the previous visible state)
# @description: Creates a display under xvfb-run, calls pygame.mouse.set_visible(False), and asserts the return equals 1 — pinning the SDL convention that set_visible returns the prior boolean state as an int.
# @timeout: 120
# @tags: usage, sdl, python, mouse
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_AUDIODRIVER=dummy

validator_run_xvfb python3 - <<'PY'
import pygame
pygame.init()
try:
    pygame.display.set_mode((80, 60))
    prev = pygame.mouse.set_visible(False)
    assert prev == 1, prev
finally:
    pygame.quit()
PY
