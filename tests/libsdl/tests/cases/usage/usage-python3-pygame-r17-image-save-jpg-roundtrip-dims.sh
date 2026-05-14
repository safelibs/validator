#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r17-image-save-jpg-roundtrip-dims
# @title: Pygame image.save JPG round-trip preserves Surface dimensions
# @description: Creates an opaque RGB Surface, saves it as JPG via pygame.image.save, reloads it, and asserts get_size() matches the original — exercising the SDL_image JPG codec dimension fidelity.
# @timeout: 120
# @tags: usage, sdl, python, image, jpg
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.jpg" <<'PY'
import sys, pygame
pygame.init()
try:
    surf = pygame.Surface((12, 9))
    surf.fill((40, 80, 160))
    pygame.image.save(surf, sys.argv[1])
    loaded = pygame.image.load(sys.argv[1])
    assert loaded.get_size() == (12, 9), loaded.get_size()
finally:
    pygame.quit()
PY
