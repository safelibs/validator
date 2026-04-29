#!/usr/bin/env bash
# @testcase: usage-python3-pygame-event-name-keydown
# @title: pygame event name keydown
# @description: Looks up the pygame event name for KEYDOWN and verifies the returned label identifies a key event.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-event-name-keydown"
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
    name = pygame.event.event_name(pygame.KEYDOWN)
    assert name.lower().startswith('key')
    print(name)
finally:
    pygame.quit()
PYCASE
