#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy

python3 - <<'PY'
import pygame

pygame.init()
try:
    first = pygame.Surface((10, 10), pygame.SRCALPHA)
    second = pygame.Surface((10, 10), pygame.SRCALPHA)
    first.fill((0, 0, 0, 0))
    second.fill((0, 0, 0, 0))
    pygame.draw.rect(first, (255, 255, 255, 255), (2, 2, 4, 4))
    pygame.draw.rect(second, (255, 255, 255, 255), (1, 1, 4, 4))

    first_mask = pygame.mask.from_surface(first)
    second_mask = pygame.mask.from_surface(second)
    collision = first_mask.overlap(second_mask, (2, 2))
    expected = (3, 3)
    if collision != expected:
        raise SystemExit(f"expected overlap at {expected}, got {collision}")
    print("overlap", collision)
finally:
    pygame.quit()
PY
