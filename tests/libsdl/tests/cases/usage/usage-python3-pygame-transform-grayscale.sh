#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-grayscale
# @title: Pygame transform grayscale
# @description: Applies pygame.transform.grayscale to a colored surface and verifies the output pixel has equal R, G, and B channels.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-grayscale"
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
    surface = pygame.Surface((16, 16))
    surface.fill((200, 100, 50))
    gray = pygame.transform.grayscale(surface)
    assert gray.get_size() == (16, 16)
    px = gray.get_at((4, 4))
    assert px.r == px.g == px.b, px
    # Luminance should sit between min and max input channels.
    assert 50 <= px.r <= 200
    print("grayscale", px)
finally:
    pygame.quit()
PY
