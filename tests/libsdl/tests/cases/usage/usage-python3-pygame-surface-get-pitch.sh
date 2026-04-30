#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-get-pitch
# @title: pygame Surface get_pitch byte alignment
# @description: Creates a small pygame.Surface and verifies Surface.get_pitch() reports a byte-stride consistent with width times bytesize, padded for SDL row alignment.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-get-pitch"
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
    width = 7
    surface = pygame.Surface((width, 4), depth=32)
    bytesize = surface.get_bytesize()
    pitch = surface.get_pitch()
    minimum = width * bytesize
    assert pitch >= minimum, f"pitch {pitch} smaller than width*bytesize {minimum}"
    assert pitch % bytesize == 0, f"pitch {pitch} not multiple of bytesize {bytesize}"
    # SDL row pitches are rounded up; allow up to 4-byte alignment slack.
    assert pitch - minimum < 4, f"unexpected pitch padding {pitch - minimum}"
    print("pitch", pitch, "bytesize", bytesize, "width", width)
finally:
    pygame.quit()
PY
