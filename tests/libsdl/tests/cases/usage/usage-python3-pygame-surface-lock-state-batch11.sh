#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-lock-state-batch11
# @title: pygame surface lock state
# @description: Locks and unlocks a pygame Surface and verifies the lock state transitions.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-lock-state-batch11"
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
    surface = pygame.Surface((2, 2))
    assert not surface.get_locked()
    surface.lock()
    assert surface.get_locked()
    surface.unlock()
    assert not surface.get_locked()
    print('lock-state')
finally:
    pygame.quit()
PYCASE
