#!/usr/bin/env bash
# @testcase: usage-python3-pygame-event-set-allowed
# @title: pygame event set_allowed and get_blocked
# @description: Blocks an event type, then allows it again via pygame.event.set_allowed and verifies pygame.event.get_blocked round-trips through both states.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-event-set-allowed"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    et = pygame.MOUSEMOTION
    pygame.event.set_blocked(et)
    assert pygame.event.get_blocked(et) is True
    pygame.event.set_allowed(et)
    assert pygame.event.get_blocked(et) is False
    # Repeat for KEYDOWN to confirm the call accepts arbitrary types.
    pygame.event.set_blocked(pygame.KEYDOWN)
    assert pygame.event.get_blocked(pygame.KEYDOWN) is True
    pygame.event.set_allowed(pygame.KEYDOWN)
    assert pygame.event.get_blocked(pygame.KEYDOWN) is False
    print("set_allowed", et, pygame.KEYDOWN)
finally:
    pygame.quit()
PY
