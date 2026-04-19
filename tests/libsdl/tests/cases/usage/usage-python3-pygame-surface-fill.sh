#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    export PYGAME_HIDE_SUPPORT_PROMPT=1
python3 - <<'PY' "$tmpdir/out.bmp"
import os; os.environ['SDL_VIDEODRIVER']='dummy'; import pygame; pygame.init(); s=pygame.Surface((8,8)); s.fill((255,0,0)); print('surface', s.get_size(), s.get_at((0,0)))
PY