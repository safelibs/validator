#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-image-tobytes-roundtrip
# @title: Pygame image tobytes/frombytes roundtrip
# @description: Serializes a small surface via pygame.image.tobytes(RGB), reconstructs it via frombytes, and verifies pixel equality.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import pygame
pygame.init()
try:
    src = pygame.Surface((4, 3))
    palette = [(10, 20, 30), (200, 80, 50), (5, 240, 180), (90, 90, 90)]
    for y in range(3):
        for x in range(4):
            src.set_at((x, y), palette[(x + y) % len(palette)])
    raw = pygame.image.tobytes(src, "RGB")
    rebuilt = pygame.image.frombytes(raw, (4, 3), "RGB")
    for y in range(3):
        for x in range(4):
            a = tuple(src.get_at((x, y)))[:3]
            b = tuple(rebuilt.get_at((x, y)))[:3]
            assert a == b, (x, y, a, b)
finally:
    pygame.quit()
PY
