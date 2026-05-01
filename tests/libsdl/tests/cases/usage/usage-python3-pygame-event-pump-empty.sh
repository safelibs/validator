#!/usr/bin/env bash
# @testcase: usage-python3-pygame-event-pump-empty
# @title: Pygame event pump on empty queue
# @description: Pumps the Pygame event loop with no input under the dummy SDL driver and confirms get() returns no events and poll() reports NOEVENT.
# @timeout: 120
# @tags: usage, event, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-event-pump-empty"
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
    pygame.event.clear()
    for _ in range(3):
        pygame.event.pump()
    events = pygame.event.get()
    assert events == [], events
    polled = pygame.event.poll()
    assert polled.type == pygame.NOEVENT
    print("pump", len(events), polled.type)
finally:
    pygame.quit()
PY
