#!/usr/bin/env bash
# @testcase: usage-python3-pygame-event-custom-type-batch11
# @title: pygame custom event type
# @description: Posts and reads a custom pygame event type.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-event-custom-type-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    event_type = pygame.event.custom_type()
    pygame.event.post(pygame.event.Event(event_type, payload='ok'))
    events = pygame.event.get(event_type)
    assert len(events) == 1 and events[0].payload == 'ok'
    print('event', event_type)
finally:
    pygame.quit()
PYCASE
