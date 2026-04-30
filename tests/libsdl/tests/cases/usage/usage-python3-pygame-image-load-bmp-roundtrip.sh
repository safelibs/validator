#!/usr/bin/env bash
# @testcase: usage-python3-pygame-image-load-bmp-roundtrip
# @title: Pygame image load BMP roundtrip
# @description: Saves a small Pygame surface as BMP and reloads it via pygame.image.load, verifying BM magic and matching dimensions.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-image-load-bmp-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

bmp_path="$tmpdir/out.bmp"

python3 - <<'PY' "$case_id" "$bmp_path"
import sys
import pygame

case_id = sys.argv[1]
bmp_path = sys.argv[2]
pygame.init()
try:
    surface = pygame.Surface((8, 6))
    surface.fill((10, 20, 30))
    pygame.image.save(surface, bmp_path)
    loaded = pygame.image.load(bmp_path)
    assert loaded.get_size() == (8, 6), loaded.get_size()
    print("loaded", loaded.get_size())
finally:
    pygame.quit()
PY

validator_require_file "$bmp_path"
head -c 2 "$bmp_path" | grep -q "BM" || {
    printf 'expected BM magic in %s\n' "$bmp_path" >&2
    exit 1
}
