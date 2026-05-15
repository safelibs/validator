#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-image-save-load-png-roundtrip-pixel
# @title: Pygame image.save then image.load PNG preserves a sentinel pixel value
# @description: Fills a 6x6 Surface with (42,84,168), saves to PNG via pygame.image.save, reloads via pygame.image.load, and asserts get_at(3,3) returns the same RGB triple, pinning the SDL_image PNG save/load round trip.
# @timeout: 60
# @tags: usage, sdl, python, image, png, roundtrip, r19
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.png" <<'PY'
import sys, pygame
pygame.init()
try:
    s = pygame.Surface((6, 6))
    s.fill((42, 84, 168))
    pygame.image.save(s, sys.argv[1])
    loaded = pygame.image.load(sys.argv[1])
    assert loaded.get_size() == (6, 6), loaded.get_size()
    r, g, b, *_ = loaded.get_at((3, 3))
    assert (r, g, b) == (42, 84, 168), (r, g, b)
finally:
    pygame.quit()
PY
