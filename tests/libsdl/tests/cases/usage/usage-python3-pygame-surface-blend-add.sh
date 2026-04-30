#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-blend-add
# @title: Pygame surface blit additive blend
# @description: Blits one surface onto another with BLEND_RGB_ADD, saves the result to BMP, verifies the BM signature, and confirms the destination pixel matches the additive sum clamped at 255.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-blend-add"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    base = pygame.Surface((16, 16))
    base.fill((100, 50, 200))
    overlay = pygame.Surface((16, 16))
    overlay.fill((50, 50, 100))
    base.blit(overlay, (0, 0), special_flags=pygame.BLEND_RGB_ADD)
    px = base.get_at((4, 4))
    # Channels are clamped at 255: 100+50, 50+50, 200+100 -> 150, 100, 255.
    assert (px.r, px.g, px.b) == (150, 100, 255), px

    out_path = os.path.join(tmpdir, "blend.bmp")
    pygame.image.save(base, out_path)
    assert os.path.getsize(out_path) > 64
    with open(out_path, "rb") as fh:
        magic = fh.read(2)
    assert magic == b"BM", magic
    print("blend", px, os.path.getsize(out_path))
finally:
    pygame.quit()
PY
