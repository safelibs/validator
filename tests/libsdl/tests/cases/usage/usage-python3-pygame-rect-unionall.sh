#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-unionall
# @title: Pygame Rect unionall
# @description: Builds a list of disjoint pygame.Rect instances and verifies unionall returns the smallest bounding rectangle that encloses every member.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-unionall"
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
    base = pygame.Rect(0, 0, 4, 4)
    others = [
        pygame.Rect(10, 0, 4, 4),
        pygame.Rect(0, 12, 6, 6),
        pygame.Rect(20, 20, 2, 2),
    ]
    bounds = base.unionall(others)
    assert bounds.left == 0
    assert bounds.top == 0
    assert bounds.right == 22, bounds
    assert bounds.bottom == 22, bounds
    # Every input rect must be fully contained.
    for r in [base] + others:
        assert bounds.contains(r), (bounds, r)
    print("unionall", bounds)
finally:
    pygame.quit()
PY
