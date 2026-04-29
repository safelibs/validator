#!/usr/bin/env bash
# @testcase: usage-python3-pygame-event-clear
# @title: pygame event clear
# @description: Exercises pygame event clear through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-event-clear"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    event_type = pygame.USEREVENT + 1
    pygame.event.post(pygame.event.Event(event_type, value=7))
    pygame.event.clear(event_type)
    assert not pygame.event.get(event_type)
    print('cleared')
finally:
    pygame.quit()
PYCASE
