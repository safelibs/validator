#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mouse-event
# @title: Pygame mouse event
# @description: Posts and reads a Pygame mouse button event in dummy video mode.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mouse-event"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    pygame.event.clear()
    pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(2, 3)))
    event = pygame.event.poll()
    assert event.type == pygame.MOUSEBUTTONDOWN and event.pos == (2, 3)
    print("mouse", event.pos)
finally:
    pygame.quit()
PY
