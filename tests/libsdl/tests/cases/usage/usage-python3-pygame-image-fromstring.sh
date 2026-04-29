#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-fromstring
# @title: Pygame image fromstring
# @description: Builds a Pygame surface from raw RGB bytes and verifies the decoded dimensions and pixel data.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-image-fromstring"
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
    data = bytes([
        255, 0, 0, 0, 255, 0,
        0, 0, 255, 255, 255, 0,
    ])
    surface = pygame.image.fromstring(data, (2, 2), "RGB")
    assert surface.get_size() == (2, 2)
    assert surface.get_at((1, 1)).r == 255
    print("fromstring", surface.get_size())
finally:
    pygame.quit()
PY
