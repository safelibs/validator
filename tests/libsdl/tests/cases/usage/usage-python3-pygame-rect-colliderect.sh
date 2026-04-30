#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-colliderect
# @title: Pygame Rect colliderect
# @description: Verifies pygame.Rect.colliderect reports overlap for intersecting rectangles and rejects strictly disjoint ones.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-colliderect"
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
    a = pygame.Rect(0, 0, 10, 10)
    b = pygame.Rect(5, 5, 10, 10)
    c = pygame.Rect(20, 20, 4, 4)
    assert a.colliderect(b)
    assert not a.colliderect(c)
    assert b.colliderect(a)
    print("colliderect", a.colliderect(b), a.colliderect(c))
finally:
    pygame.quit()
PY
