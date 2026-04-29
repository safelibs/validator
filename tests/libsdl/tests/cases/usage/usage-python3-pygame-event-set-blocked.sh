#!/usr/bin/env bash
# @testcase: usage-python3-pygame-event-set-blocked
# @title: pygame event set blocked
# @description: Exercises pygame event set blocked through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-event-set-blocked"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    pygame.event.set_blocked(pygame.MOUSEMOTION)
    assert pygame.event.get_blocked(pygame.MOUSEMOTION)
    print('blocked')
finally:
    pygame.quit()
PY
