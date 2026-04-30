#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-collidepoint
# @title: Pygame Rect collidepoint
# @description: Exercises pygame.Rect.collidepoint with interior, edge, and exterior points and verifies the documented half-open semantics on the right and bottom edges.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-collidepoint"
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
    rect = pygame.Rect(10, 20, 30, 40)  # x in [10, 40), y in [20, 60)

    # Strictly inside.
    assert rect.collidepoint(15, 25) is True
    assert rect.collidepoint((39, 59)) is True

    # Top-left corner is inclusive.
    assert rect.collidepoint(10, 20) is True

    # Bottom-right corner is exclusive (half-open semantics).
    assert rect.collidepoint(40, 60) is False
    assert rect.collidepoint(40, 30) is False
    assert rect.collidepoint(15, 60) is False

    # Outside the rect entirely.
    assert rect.collidepoint(0, 0) is False
    assert rect.collidepoint(100, 100) is False

    print(case_id, "ok")
finally:
    pygame.quit()
PY
