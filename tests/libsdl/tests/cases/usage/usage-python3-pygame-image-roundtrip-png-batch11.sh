#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-roundtrip-png-batch11
# @title: pygame image PNG roundtrip
# @description: Saves and reloads a PNG image through pygame image APIs.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-image-roundtrip-png-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    path = os.path.join(tmpdir, 'roundtrip.png')
    surface = pygame.Surface((3, 3))
    surface.fill((30, 60, 90))
    pygame.image.save(surface, path)
    loaded = pygame.image.load(path)
    assert loaded.get_size() == (3, 3)
    assert loaded.get_at((0, 0))[:3] == (30, 60, 90)
    print('png')
finally:
    pygame.quit()
PYCASE
