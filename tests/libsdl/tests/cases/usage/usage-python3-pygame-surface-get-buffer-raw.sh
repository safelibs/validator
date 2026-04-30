#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-get-buffer-raw
# @title: Pygame surface get_buffer raw
# @description: Reads a Surface's raw pixel buffer via Surface.get_buffer().raw and verifies its length matches pitch*height for the surface format.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-get-buffer-raw"
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
    width, height = 16, 8
    surface = pygame.Surface((width, height), pygame.SRCALPHA)
    surface.fill((1, 2, 3, 4))

    buf = surface.get_buffer()
    raw = buf.raw
    assert isinstance(raw, (bytes, bytearray)), type(raw)

    pitch = surface.get_pitch()
    expected = pitch * height
    assert len(raw) == expected, (len(raw), expected)

    # length() helper agrees with .raw.
    assert buf.length == expected, (buf.length, expected)

    print(case_id, "ok", pitch, len(raw))
finally:
    pygame.quit()
PY
