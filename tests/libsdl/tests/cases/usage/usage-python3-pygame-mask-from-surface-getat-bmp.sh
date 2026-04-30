#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-from-surface-getat-bmp
# @title: pygame Mask.from_surface get_at count centroid
# @description: Builds a pygame Mask via Mask.from_surface from an alpha surface with a known opaque rectangle, asserts get_at hits, the total count, and the centroid, then saves the source surface to BMP and verifies the BM magic.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-from-surface-getat-bmp"
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
    surface = pygame.Surface((6, 6), pygame.SRCALPHA)
    pygame.draw.rect(surface, (255, 255, 255, 255), pygame.Rect(2, 2, 2, 2))

    mask = pygame.mask.from_surface(surface)
    assert mask.get_at((2, 2)) == 1
    assert mask.get_at((3, 3)) == 1
    assert mask.get_at((0, 0)) == 0
    assert mask.count() == 4, mask.count()
    cx, cy = mask.centroid()
    # 2x2 rect at (2,2)..(3,3) -> centroid floors to (2,2)
    assert (cx, cy) == (2, 2), (cx, cy)

    out_path = os.path.join(tmpdir, "mask.bmp")
    pygame.image.save(surface, out_path)
    with open(out_path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM", head
    print("mask-from-surface", mask.count(), (cx, cy))
finally:
    pygame.quit()
PYCASE

grep -l BM "$tmpdir"/mask.bmp >/dev/null
