#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-time-set-timer-loops
# @title: Pygame time.set_timer with explicit loop count
# @description: Schedules a USEREVENT timer with loops=3 and verifies exactly three events arrive on the queue before it stops.
# @timeout: 180
# @tags: usage, sdl, python
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
    event_type = pygame.USEREVENT + 7
    pygame.event.clear()
    pygame.time.set_timer(event_type, 5, loops=3)

    received = 0
    for _ in range(3):
        evt = pygame.event.wait(timeout=2000)
        assert evt.type == event_type, f"unexpected event type: {evt.type}"
        received += 1
    assert received == 3

    # After loops have fired, the timer should not produce a 4th event quickly.
    pygame.event.clear()
    pygame.time.wait(50)
    extra = [e for e in pygame.event.get() if e.type == event_type]
    assert extra == [], f"expected no further timer events, got {extra}"
finally:
    pygame.quit()
PY
