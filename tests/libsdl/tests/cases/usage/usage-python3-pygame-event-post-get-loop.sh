#!/usr/bin/env bash
# @testcase: usage-python3-pygame-event-post-get-loop
# @title: pygame event.post and event.get loop
# @description: Posts several distinct USEREVENT-derived events into the pygame queue and drains them through pygame.event.get to verify FIFO order and that custom payload attributes round-trip intact.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-event-post-get-loop"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import sys
import pygame

case_id = sys.argv[1]

pygame.init()
try:
    pygame.display.init()
    pygame.event.clear()
    base = pygame.USEREVENT
    payloads = [
        (base + 1, {"code": 11, "label": "alpha"}),
        (base + 2, {"code": 22, "label": "beta"}),
        (base + 3, {"code": 33, "label": "gamma"}),
    ]
    for ev_type, attrs in payloads:
        pygame.event.post(pygame.event.Event(ev_type, attrs))

    drained = []
    for ev in pygame.event.get():
        if ev.type >= base:
            drained.append((ev.type, ev.code, ev.label))

    assert drained == [(base + 1, 11, "alpha"),
                       (base + 2, 22, "beta"),
                       (base + 3, 33, "gamma")], drained
    print("event-loop", drained)
finally:
    pygame.quit()
PYCASE
