#!/usr/bin/env bash
# @testcase: usage-python3-pygame-timer-event
# @title: Pygame timer event
# @description: Schedules a one-shot timer event in Pygame and verifies the expected user event arrives.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-timer-event"
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
    event_type = pygame.USEREVENT + 3
    pygame.event.clear()
    pygame.time.set_timer(event_type, 5, loops=1)
    event = pygame.event.wait()
    assert event.type == event_type
    print("timer", event.type)
finally:
    pygame.quit()
PY
