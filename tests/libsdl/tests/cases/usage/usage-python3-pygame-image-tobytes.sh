#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-tobytes
# @title: Pygame image tobytes
# @description: Serializes a small Surface with pygame.image.tobytes in RGB and RGBA modes and verifies byte-string lengths match width*height*channels.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-image-tobytes"
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
    width, height = 8, 4
    surface = pygame.Surface((width, height), pygame.SRCALPHA)
    surface.fill((10, 20, 30, 200))

    rgb = pygame.image.tobytes(surface, "RGB")
    rgba = pygame.image.tobytes(surface, "RGBA")

    assert isinstance(rgb, (bytes, bytearray)), type(rgb)
    assert isinstance(rgba, (bytes, bytearray)), type(rgba)
    assert len(rgb) == width * height * 3, len(rgb)
    assert len(rgba) == width * height * 4, len(rgba)

    # First pixel matches the fill value.
    assert tuple(rgb[0:3]) == (10, 20, 30), tuple(rgb[0:3])
    assert tuple(rgba[0:4]) == (10, 20, 30, 200), tuple(rgba[0:4])

    print(case_id, "ok", len(rgb), len(rgba))
finally:
    pygame.quit()
PY
