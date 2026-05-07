#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-image-save-load-bmp-roundtrip
# @title: Pygame image.save then image.load round-trips a BMP surface byte-for-byte
# @description: Builds a 4x3 surface, writes solid green pixels via fill, saves to BMP, reloads via image.load, and asserts the reloaded surface dimensions match and a probe pixel still reads (0, 200, 0).
# @timeout: 120
# @tags: usage, sdl, python, image
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/probe.bmp" <<'PY'
import sys
import pygame

path = sys.argv[1]
pygame.init()
try:
    surf = pygame.Surface((4, 3))
    surf.fill((0, 200, 0))
    pygame.image.save(surf, path)
    loaded = pygame.image.load(path)
    assert loaded.get_size() == (4, 3), loaded.get_size()
    rgb = loaded.get_at((1, 1))[:3]
    assert rgb == (0, 200, 0), rgb
finally:
    pygame.quit()
PY
