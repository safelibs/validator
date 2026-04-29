#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-save-bmp
# @title: pygame image save BMP
# @description: Saves a pygame surface as BMP, verifies the file begins with the BM magic bytes, and reloads it to confirm the original dimensions.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-image-save-bmp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import os
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    path = os.path.join(tmpdir, "saved.bmp")
    surface = pygame.Surface((3, 2))
    surface.fill((90, 120, 200))
    pygame.image.save(surface, path)
    with open(path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM"
    loaded = pygame.image.load(path)
    assert loaded.get_size() == (3, 2)
    print("bmp", loaded.get_size())
finally:
    pygame.quit()
PY
