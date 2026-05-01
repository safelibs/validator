#!/usr/bin/env bash
# @testcase: usage-python3-pygame-joystick-empty-init
# @title: pygame.joystick init with no devices
# @description: Initializes pygame.joystick under the headless SDL dummy driver where no input devices are present, then confirms get_init returns True, get_count is zero, instantiating Joystick(0) raises an error, and joystick.quit cleanly tears the subsystem down.
# @timeout: 120
# @tags: usage, joystick
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-joystick-empty-init"

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    pygame.joystick.init()
    assert pygame.joystick.get_init() is True
    count = pygame.joystick.get_count()
    assert count == 0, count

    raised = False
    try:
        pygame.joystick.Joystick(0)
    except pygame.error:
        raised = True
    except Exception:
        raised = True
    assert raised, "expected pygame.error opening Joystick(0) with no devices"

    pygame.joystick.quit()
    assert pygame.joystick.get_init() is False
    print("joystick", count)
finally:
    pygame.quit()
PY
