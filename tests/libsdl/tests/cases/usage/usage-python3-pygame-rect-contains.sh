#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-contains
# @title: pygame rect contains
# @description: Calls pygame Rect.contains with a fully enclosed rectangle and verifies the outer reports containment while the inner does not contain the outer.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-contains"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import os
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    outer = pygame.Rect(0, 0, 10, 10)
    inner = pygame.Rect(2, 3, 4, 5)
    assert outer.contains(inner)
    assert not inner.contains(outer)
    print("contains", outer.contains(inner))
finally:
    pygame.quit()
PY
