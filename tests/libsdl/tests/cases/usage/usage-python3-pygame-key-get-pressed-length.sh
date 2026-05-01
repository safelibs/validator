#!/usr/bin/env bash
# @testcase: usage-python3-pygame-key-get-pressed-length
# @title: Pygame key get_pressed length
# @description: Calls pygame.key.get_pressed() under the dummy driver and verifies the returned ScancodeWrapper is non-empty and reports no keys held.
# @timeout: 120
# @tags: usage, input, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-key-get-pressed-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    pygame.display.set_mode((1, 1))
    pygame.event.pump()
    state = pygame.key.get_pressed()
    length = len(state)
    assert length > 100, length
    assert state[pygame.K_a] == 0
    assert state[pygame.K_SPACE] == 0
    pressed_count = sum(1 for i in range(length) if state[i])
    assert pressed_count == 0
    print("keys", length, pressed_count)
finally:
    pygame.quit()
PY
