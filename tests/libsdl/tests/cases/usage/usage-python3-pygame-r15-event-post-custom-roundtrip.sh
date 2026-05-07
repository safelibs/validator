#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-event-post-custom-roundtrip
# @title: Pygame event.post then event.get returns the user-event with original attributes
# @description: Allocates a custom user event type via pygame.event.custom_type, posts an Event with attribute payload='r15', and asserts pygame.event.get returns at least one event matching the custom type whose payload attribute equals 'r15'.
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
    pygame.display.set_mode((1, 1))
    custom = pygame.event.custom_type()
    pygame.event.post(pygame.event.Event(custom, {'payload': 'r15'}))
    pygame.event.pump()
    matched = [e for e in pygame.event.get() if e.type == custom]
    assert matched, 'expected at least one custom event'
    assert matched[0].payload == 'r15', matched[0].payload
finally:
    pygame.quit()
PY
