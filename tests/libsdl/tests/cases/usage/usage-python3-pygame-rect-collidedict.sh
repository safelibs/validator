#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-collidedict
# @title: pygame Rect.collidedict and collidedictall
# @description: Builds a dict whose values are pygame.Rect (use_values=1 mode) and verifies Rect.collidedict returns one overlapping entry and Rect.collidedictall returns every overlapping label.
# @timeout: 120
# @tags: usage, rect
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-rect-collidedict"

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    probe = pygame.Rect(10, 10, 5, 5)
    # pygame.Rect is unhashable, so it must be the dict *value* and the key
    # is a string label. use_values=1 tells collidedict to consider values.
    rects = {
        "far-tl": pygame.Rect(0, 0, 4, 4),
        "overlap-a": pygame.Rect(12, 12, 6, 6),
        "far-br": pygame.Rect(50, 50, 4, 4),
        "overlap-b": pygame.Rect(13, 13, 2, 2),
    }
    hit = probe.collidedict(rects, 1)
    assert hit is not None, "expected a colliding entry"
    assert hit[0] in {"overlap-a", "overlap-b"}, hit

    all_hits = probe.collidedictall(rects, 1)
    labels = sorted(label for label, _ in all_hits)
    assert labels == ["overlap-a", "overlap-b"], labels

    miss = pygame.Rect(200, 200, 1, 1).collidedict(rects, 1)
    assert miss is None, miss
    print("collidedict", labels)
finally:
    pygame.quit()
PY
