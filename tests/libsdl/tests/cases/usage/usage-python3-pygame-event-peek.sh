#!/usr/bin/env bash
# @testcase: usage-python3-pygame-event-peek
# @title: Pygame event peek
# @description: Posts a custom event in Pygame and verifies event.peek observes the queued event type.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-event-peek"
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
    event_type = pygame.USEREVENT + 4
    pygame.event.clear()
    pygame.event.post(pygame.event.Event(event_type, value=7))
    assert pygame.event.peek(event_type)
    event = pygame.event.poll()
    assert event.type == event_type and event.value == 7
    print("peek", event.value)
finally:
    pygame.quit()
PY
