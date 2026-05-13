#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-image-load-png-roundtrip-dims
# @title: Pygame image.save PNG then image.load round-trips a 5x7 Surface size
# @description: Builds a 5x7 Surface, saves as PNG, reloads it, and asserts the reloaded Surface get_size() is (5, 7) — pinning the PNG codec dimensions round trip, distinct from the BMP r15 round trip.
# @timeout: 120
# @tags: usage, sdl, python, image, png
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/probe.png" <<'PY'
import sys
import pygame

path = sys.argv[1]
pygame.init()
try:
    surf = pygame.Surface((5, 7))
    surf.fill((10, 100, 200))
    pygame.image.save(surf, path)
    loaded = pygame.image.load(path)
    assert loaded.get_size() == (5, 7), loaded.get_size()
finally:
    pygame.quit()
PY
