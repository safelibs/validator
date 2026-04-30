#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-bitsize-bytesize
# @title: pygame Surface bitsize and bytesize
# @description: Creates Pygame surfaces at requested depths (8, 16, 32) and confirms Surface.get_bitsize and Surface.get_bytesize report consistent values whose ratio equals 8 bits per byte.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-bitsize-bytesize"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    results = {}
    for depth in (8, 16, 32):
        surface = pygame.Surface((4, 4), depth=depth)
        bits = surface.get_bitsize()
        bytes_ = surface.get_bytesize()
        assert bits == depth, (depth, bits)
        # bytesize is the byte stride per pixel; for 8/16/32 it must match bits/8.
        assert bytes_ == bits // 8, (bits, bytes_)
        results[depth] = (bits, bytes_)
    print("sizes", results)
finally:
    pygame.quit()
PY
