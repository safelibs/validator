#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-tostring
# @title: Pygame image tostring
# @description: Serializes a Pygame surface to RGB bytes and verifies the expected byte length.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-image-tostring"
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
    surface = pygame.Surface((4, 4))
    data = pygame.image.tostring(surface, "RGB")
    assert len(data) == 4 * 4 * 3
    print("bytes", len(data))
finally:
    pygame.quit()
PY
