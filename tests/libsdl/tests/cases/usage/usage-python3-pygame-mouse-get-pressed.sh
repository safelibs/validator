#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mouse-get-pressed
# @title: pygame mouse.get_pressed
# @description: Pumps the pygame event queue with the dummy video driver and confirms pygame.mouse.get_pressed returns a tuple of three button states with no buttons currently held down.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mouse-get-pressed"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    pygame.display.set_mode((4, 4))
    pygame.event.pump()
    state = pygame.mouse.get_pressed()
    # Default 3-button signature; defaulted form must always be length 3.
    assert isinstance(state, tuple), type(state)
    assert len(state) == 3, state
    for entry in state:
        assert entry in (0, 1, False, True), state
    # No interactive input in dummy mode -> nothing is held.
    assert not any(state), state
    print("pressed", state)
finally:
    pygame.quit()
PY
