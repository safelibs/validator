#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-smoothscale-by
# @title: pygame transform smoothscale_by factor
# @description: Resizes a pygame surface using transform.smoothscale_by with a fractional factor, saves the result as BMP, checks the BM magic, and asserts the new dimensions.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-smoothscale-by"
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
    surface = pygame.Surface((16, 8))
    surface.fill((40, 60, 120))
    scaled = pygame.transform.smoothscale_by(surface, 0.5)
    assert scaled.get_size() == (8, 4), scaled.get_size()

    out_path = os.path.join(tmpdir, "scaled.bmp")
    pygame.image.save(scaled, out_path)
    with open(out_path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM", head
    print("smoothscale_by", scaled.get_size())
finally:
    pygame.quit()
PYCASE

grep -l BM "$tmpdir"/scaled.bmp >/dev/null
