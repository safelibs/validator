#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-load
# @title: Pygame image load
# @description: Saves and reloads a bitmap image through Pygame image helpers.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-image-load"
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
    path = os.path.join(tmpdir, "image.bmp")
    surface = pygame.Surface((5, 4))
    surface.fill((0, 128, 255))
    pygame.image.save(surface, path)
    loaded = pygame.image.load(path)
    assert loaded.get_size() == (5, 4)
    print("load", loaded.get_size())
finally:
    pygame.quit()
PY
