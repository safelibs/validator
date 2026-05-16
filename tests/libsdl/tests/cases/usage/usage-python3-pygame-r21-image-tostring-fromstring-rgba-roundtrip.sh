#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-image-tostring-fromstring-rgba-roundtrip
# @title: Pygame image.tostring/fromstring RGBA round-trip preserves a sentinel pixel
# @description: Builds an 8x4 SRCALPHA Surface, paints a unique RGBA sentinel at (2,1), serializes via image.tostring(RGBA), deserializes via fromstring with the same dims, and asserts the sentinel pixel matches the original, pinning the SDL-backed RGBA byte serialization round-trip.
# @timeout: 60
# @tags: usage, sdl, python, image, rgba, roundtrip, r21
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
pygame.init()
try:
    s = pygame.Surface((8, 4), pygame.SRCALPHA)
    s.fill((0, 0, 0, 0))
    sentinel = (200, 100, 50, 220)
    s.set_at((2, 1), sentinel)
    raw = pygame.image.tostring(s, 'RGBA')
    s2 = pygame.image.fromstring(raw, (8, 4), 'RGBA')
    p = s2.get_at((2, 1))
    assert (p.r, p.g, p.b, p.a) == sentinel, p
finally:
    pygame.quit()
PY
