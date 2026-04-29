#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-move-ip
# @title: pygame rect move ip
# @description: Mutates a pygame Rect in place with move_ip and verifies the translated top-left coordinates.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-move-ip"
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
    rect = pygame.Rect(5, 4, 3, 2)
    rect.move_ip(-2, 3)
    assert rect.topleft == (3, 7)
    print(rect.topleft)
finally:
    pygame.quit()
PYCASE
