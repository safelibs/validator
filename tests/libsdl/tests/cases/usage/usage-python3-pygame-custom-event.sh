#!/usr/bin/env bash
# @testcase: usage-python3-pygame-custom-event
# @title: Pygame custom event
# @description: Posts a custom Pygame user event and verifies the SDL-backed queue returns it.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-custom-event"
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
    event_type = pygame.USEREVENT + 1
    pygame.event.clear()
    pygame.event.post(pygame.event.Event(event_type, value="ok"))
    event = pygame.event.poll()
    assert event.type == event_type and event.value == "ok"
    print("event", event.value)
finally:
    pygame.quit()
PY
