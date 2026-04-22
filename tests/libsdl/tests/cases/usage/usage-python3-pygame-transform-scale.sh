#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame

source = pygame.Surface((4, 4))
destination = pygame.Surface((8, 8))
out = pygame.transform.scale(source, (8, 8), destination)
if out.get_size() != (8, 8):
    raise SystemExit(f"unexpected scaled size: {out.get_size()}")
print("scaled", out.get_size())
PY
