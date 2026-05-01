#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-jpg-roundtrip
# @title: pygame.image JPEG save and reload
# @description: Saves a 16x16 solid-color surface to a JPEG file via pygame.image.save and reloads it, confirming the file begins with the JPEG SOI marker and that the decoded pixel color stays close to the source within JPEG quantization tolerance.
# @timeout: 120
# @tags: usage, image
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-image-jpg-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.init()
try:
    src = pygame.Surface((16, 16))
    src.fill((200, 100, 50))
    path = os.path.join(tmpdir, "out.jpg")
    pygame.image.save(src, path)
    assert os.path.exists(path)
    with open(path, "rb") as f:
        head = f.read(3)
    assert head[:2] == b"\xff\xd8", head  # JPEG SOI
    loaded = pygame.image.load(path)
    assert loaded.get_size() == (16, 16), loaded.get_size()
    px = loaded.get_at((8, 8))
    assert abs(px.r - 200) <= 12, px.r
    assert abs(px.g - 100) <= 12, px.g
    assert abs(px.b - 50) <= 12, px.b
    print("jpg", os.path.getsize(path), tuple(px)[:3])
finally:
    pygame.quit()
PY
