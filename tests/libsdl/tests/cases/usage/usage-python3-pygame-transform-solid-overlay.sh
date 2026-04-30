#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-solid-overlay
# @title: Pygame transform laplacian highlights edge pixels
# @description: Applies pygame.transform.laplacian to a Surface that contains a single solid block (pygame 2.5 has no transform.solid_overlay) and verifies the result has matching dimensions, that interior block pixels collapse toward zero (no local edge), and that pixels along the block boundary report a non-zero edge response.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-solid-overlay"
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
    src = pygame.Surface((16, 16))
    src.fill((0, 0, 0))
    pygame.draw.rect(src, (255, 255, 255), pygame.Rect(6, 6, 4, 4))

    edges = pygame.transform.laplacian(src)
    assert edges.get_size() == (16, 16), edges.get_size()

    # Interior of the solid block - all neighbours equal the centre, so the
    # laplacian collapses to (near) zero.
    interior = edges.get_at((7, 7))
    assert interior.r < 16, interior

    # A pixel on the block boundary has differing neighbours and so must
    # produce a non-zero edge response.
    boundary = edges.get_at((6, 6))
    assert boundary.r > 0, boundary

    # Original surface must not have been mutated.
    orig = src.get_at((7, 7))
    assert (orig.r, orig.g, orig.b) == (255, 255, 255), (orig.r, orig.g, orig.b)
    print(case_id, "ok", interior.r, boundary.r)
finally:
    pygame.quit()
PY
