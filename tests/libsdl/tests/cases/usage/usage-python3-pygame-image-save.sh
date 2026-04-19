#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    export PYGAME_HIDE_SUPPORT_PROMPT=1
python3 - <<'PY' "$tmpdir/out.bmp"
import os, sys; os.environ['SDL_VIDEODRIVER']='dummy'; import pygame; pygame.init(); s=pygame.Surface((4,4)); s.fill((0,255,0)); pygame.image.save(s, sys.argv[1]); print('saved', sys.argv[1])
PY