#!/usr/bin/env bash
# @testcase: usage-python3-pygame-key-get-focused
# @title: pygame key.get_focused
# @description: Initializes a pygame display with the dummy driver and confirms pygame.key.get_focused returns a boolean-typed value queryable without error.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-key-get-focused"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    pygame.display.set_mode((4, 4))
    focused = pygame.key.get_focused()
    # Pygame returns 0/1 or False/True depending on version; both must coerce to bool.
    assert focused in (0, 1, False, True), focused
    coerced = bool(focused)
    assert coerced in (False, True), coerced
    print("focused", focused, coerced)
finally:
    pygame.quit()
PY
