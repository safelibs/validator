#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-frombytes-roundtrip
# @title: Pygame image tostring frombytes roundtrip
# @description: Serializes a Pygame surface to RGB bytes and rebuilds it via pygame.image.frombytes, verifying dimensions and byte length match.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-image-frombytes-roundtrip"
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
    src = pygame.Surface((5, 3))
    src.fill((100, 150, 200))
    raw = pygame.image.tostring(src, "RGB")
    assert len(raw) == 5 * 3 * 3
    rebuilt = pygame.image.frombytes(raw, (5, 3), "RGB")
    assert rebuilt.get_size() == (5, 3)
    raw2 = pygame.image.tostring(rebuilt, "RGB")
    assert raw == raw2
    print("frombytes", rebuilt.get_size(), len(raw))
finally:
    pygame.quit()
PY
