#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-threshold
# @title: pygame transform threshold
# @description: Uses pygame.transform.threshold against a known reference colour to count matching pixels on a tiny surface and verifies the returned match count equals the seeded pixels.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-threshold"
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
    W, H = 6, 6
    total = W * H
    red_pixels = [(1, 1), (4, 2), (3, 5)]

    src = pygame.Surface((W, H))
    src.fill((0, 0, 0))
    for x, y in red_pixels:
        src.set_at((x, y), (255, 0, 0))

    dest = pygame.Surface((W, H))
    # pygame.transform.threshold returns the count of pixels in `src` that
    # match `search_color` within `threshold`; with default set_behavior=1
    # the non-matching pixels in `dest` get painted with `set_color`.
    matches = pygame.transform.threshold(
        dest, src, (255, 0, 0), (1, 1, 1, 0), (0, 255, 0)
    )
    expected_matches = len(red_pixels)
    assert matches == expected_matches, (matches, total, expected_matches)

    green_pixels = sum(
        1
        for y in range(dest.get_height())
        for x in range(dest.get_width())
        if dest.get_at((x, y))[:3] == (0, 255, 0)
    )
    assert green_pixels == total - expected_matches, (green_pixels, total, expected_matches)

    out_path = os.path.join(tmpdir, "threshold.bmp")
    pygame.image.save(dest, out_path)
    with open(out_path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM", head
    print("threshold", matches, green_pixels)
finally:
    pygame.quit()
PYCASE

grep -l BM "$tmpdir"/threshold.bmp >/dev/null
