#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-event-post-get-roundtrip
# @title: Pygame event.post enqueues a custom event that event.get returns intact
# @description: Allocates a custom event type via pygame.event.custom_type, posts an Event carrying a payload dict, and asserts event.get returns exactly one Event with the matching type and payload attribute.
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
    pygame.event.clear()
    custom = pygame.event.custom_type()
    posted = pygame.event.post(pygame.event.Event(custom, {"payload": "r13"}))
    assert posted is True or posted is None  # post returns True in newer pygame, None historically
    pygame.event.pump()
    events = pygame.event.get()
    matches = [e for e in events if e.type == custom]
    assert len(matches) == 1, [e.type for e in events]
    assert matches[0].payload == "r13", matches[0].payload
finally:
    pygame.quit()
PY
