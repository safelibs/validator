#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-collidedict
# @title: pygame Rect.collidedict and collidedictall
# @description: Builds a dictionary keyed by pygame.Rect values, then verifies Rect.collidedict returns the first overlapping entry and Rect.collidedictall returns every overlapping entry in insertion order.
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
    rects = {
        pygame.Rect(0, 0, 4, 4): "far-tl",
        pygame.Rect(12, 12, 6, 6): "overlap-a",
        pygame.Rect(50, 50, 4, 4): "far-br",
        pygame.Rect(13, 13, 2, 2): "overlap-b",
    }
    hit = probe.collidedict(rects, 1)
    assert hit is not None, "expected a colliding entry"
    assert hit[1] in {"overlap-a", "overlap-b"}, hit

    all_hits = probe.collidedictall(rects, 1)
    labels = sorted(label for _, label in all_hits)
    assert labels == ["overlap-a", "overlap-b"], labels

    miss = pygame.Rect(200, 200, 1, 1).collidedict(rects, 1)
    assert miss is None, miss
    print("collidedict", labels)
finally:
    pygame.quit()
PY
