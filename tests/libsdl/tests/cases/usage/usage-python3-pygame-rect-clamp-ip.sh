#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-clamp-ip
# @title: pygame rect clamp_ip
# @description: Clamps a pygame Rect that pokes past an outer rectangle and verifies the clamped rectangle stays within the outer bounds.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-clamp-ip"
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
    outer = pygame.Rect(0, 0, 10, 10)
    inner = pygame.Rect(8, 9, 5, 4)
    inner.clamp_ip(outer)
    assert inner.right <= outer.right
    assert inner.bottom <= outer.bottom
    print("clamp", inner)
finally:
    pygame.quit()
PY
