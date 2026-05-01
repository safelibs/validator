#!/usr/bin/env bash
# @testcase: usage-python3-pygame-display-list-modes-dummy
# @title: Pygame display list_modes under dummy
# @description: Calls pygame.display.list_modes() under the dummy video driver and verifies it returns either -1 or a list of (w, h) pairs with positive dimensions.
# @timeout: 120
# @tags: usage, display, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-display-list-modes-dummy"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    pygame.display.init()
    modes = pygame.display.list_modes()
    if modes == -1:
        print("modes", "any")
    else:
        assert isinstance(modes, list)
        for entry in modes:
            assert isinstance(entry, tuple)
            assert len(entry) == 2
            w, h = entry
            assert w > 0 and h > 0
        print("modes", len(modes))
finally:
    pygame.quit()
PY
