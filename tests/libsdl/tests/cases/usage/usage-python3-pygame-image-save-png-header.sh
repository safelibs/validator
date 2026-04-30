#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-save-png-header
# @title: Pygame image save PNG header
# @description: Saves a pygame surface as PNG, checks the on-disk PNG signature bytes, and reloads the file to confirm the original pixel color survives the round trip.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-image-save-png-header"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    path = os.path.join(tmpdir, "saved.png")
    surface = pygame.Surface((8, 8))
    surface.fill((12, 200, 77))
    pygame.image.save(surface, path)
    size = os.path.getsize(path)
    assert size > 8, size
    with open(path, "rb") as fh:
        head = fh.read(8)
    assert head == b"\x89PNG\r\n\x1a\n", head
    loaded = pygame.image.load(path)
    assert loaded.get_size() == (8, 8)
    px = loaded.get_at((3, 3))
    assert (px.r, px.g, px.b) == (12, 200, 77), px
    print("png", size, px)
finally:
    pygame.quit()
PY
