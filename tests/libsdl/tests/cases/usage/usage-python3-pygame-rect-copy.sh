#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-copy
# @title: pygame Rect copy independence
# @description: Copies a pygame.Rect via Rect.copy(), mutates the copy in place, and verifies the original Rect remains untouched and the two compare unequal afterwards.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-copy"
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
    original = pygame.Rect(5, 7, 30, 40)
    clone = original.copy()
    assert clone == original
    assert clone is not original
    clone.move_ip(11, 13)
    # Mutating the copy must not touch the original.
    assert original == pygame.Rect(5, 7, 30, 40)
    assert clone.topleft == (16, 20)
    assert clone != original
    # Resizing the copy is also independent.
    clone.width = 99
    assert original.width == 30
    print("copy", original, clone)
finally:
    pygame.quit()
PY
