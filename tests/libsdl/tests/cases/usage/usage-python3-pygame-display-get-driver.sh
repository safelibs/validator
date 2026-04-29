#!/usr/bin/env bash
# @testcase: usage-python3-pygame-display-get-driver
# @title: pygame display get driver
# @description: Opens a dummy pygame display surface and verifies pygame reports the configured dummy display backend.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-display-get-driver"
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
    pygame.display.set_mode((4, 4))
    assert pygame.display.get_driver() == 'dummy'
    print(pygame.display.get_driver())
finally:
    pygame.quit()
PYCASE
