#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-event-peek-empty-queue-false
# @title: Pygame event.peek on an empty queue returns False
# @description: Calls pygame.event.clear() then pygame.event.peek() and asserts the return is False, pinning the empty event-queue probe semantics on the SDL backend.
# @timeout: 60
# @tags: usage, sdl, python, event
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
    pygame.event.pump()
    pygame.event.clear()
    res = pygame.event.peek()
    assert res is False, res
finally:
    pygame.quit()
PY
