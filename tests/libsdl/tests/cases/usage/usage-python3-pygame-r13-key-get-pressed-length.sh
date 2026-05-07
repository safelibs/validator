#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-key-get-pressed-length
# @title: Pygame key.get_pressed returns a sequence indexable by SDL scancodes
# @description: Initializes a dummy display, calls pygame.event.pump and pygame.key.get_pressed, asserts the returned sequence has positive length and that probing a known scancode (K_a) does not raise and returns a boolean-ish value.
# @timeout: 60
# @tags: usage, sdl, python, key
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
    pygame.display.set_mode((4, 4))
    pygame.event.pump()
    pressed = pygame.key.get_pressed()
    assert len(pressed) > 0, len(pressed)
    # Indexing by a well-known constant must not raise.
    state = pressed[pygame.K_a]
    # State should coerce to a bool; in dummy mode no key is pressed.
    assert bool(state) is False, state
finally:
    pygame.quit()
PY
