#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-set-at-get-at
# @title: Pygame Surface set_at and get_at
# @description: Writes individual pixels via Pygame Surface.set_at and reads them back via get_at to confirm the SDL pixel addressing matches.
# @timeout: 120
# @tags: usage, surface, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-set-at-get-at"
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
    surf = pygame.Surface((4, 4))
    surf.fill((0, 0, 0))
    surf.set_at((0, 0), (255, 0, 0))
    surf.set_at((3, 3), (0, 255, 0))
    surf.set_at((1, 2), (0, 0, 255))
    a = surf.get_at((0, 0))
    b = surf.get_at((3, 3))
    c = surf.get_at((1, 2))
    d = surf.get_at((2, 2))
    assert (a.r, a.g, a.b) == (255, 0, 0)
    assert (b.r, b.g, b.b) == (0, 255, 0)
    assert (c.r, c.g, c.b) == (0, 0, 255)
    assert (d.r, d.g, d.b) == (0, 0, 0)
    print("pixels", a, b, c, d)
finally:
    pygame.quit()
PY
