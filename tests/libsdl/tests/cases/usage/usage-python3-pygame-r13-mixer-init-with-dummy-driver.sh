#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r13-mixer-init-with-dummy-driver
# @title: Pygame mixer.init reports a positive frequency under the dummy audio driver
# @description: Initializes pygame.mixer under SDL_AUDIODRIVER=dummy, asserts get_init returns a non-None tuple whose frequency is > 0 and channel count is in {1,2}, then quits the mixer cleanly.
# @timeout: 60
# @tags: usage, sdl, python, mixer
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
    pygame.mixer.init()
    info = pygame.mixer.get_init()
    assert info is not None, info
    freq, fmt, channels = info
    assert freq > 0, freq
    assert channels in (1, 2), channels
    pygame.mixer.quit()
    assert pygame.mixer.get_init() is None
finally:
    pygame.quit()
PY
