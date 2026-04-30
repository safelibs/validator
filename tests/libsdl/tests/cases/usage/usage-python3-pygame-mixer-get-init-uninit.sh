#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mixer-get-init-uninit
# @title: pygame mixer get_init before and after init
# @description: Calls pygame.mixer.get_init both before and after initializing the mixer with the dummy driver, confirming None is returned uninitialized and a (frequency, format, channels) tuple after init.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mixer-get-init-uninit"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
# Ensure mixer starts uninitialized.
pygame.mixer.quit()
assert pygame.mixer.get_init() is None, pygame.mixer.get_init()

pygame.mixer.init(frequency=22050, size=-16, channels=1)
try:
    info = pygame.mixer.get_init()
    assert info is not None, info
    assert len(info) == 3, info
    frequency, fmt, channels = info
    assert frequency == 22050, info
    assert channels == 1, info
    # SDL audio formats encode size in the low byte; -16 maps to a non-zero magnitude.
    assert isinstance(fmt, int) and fmt != 0, info
    print("mixer", info)
finally:
    pygame.mixer.quit()
    assert pygame.mixer.get_init() is None
PY
