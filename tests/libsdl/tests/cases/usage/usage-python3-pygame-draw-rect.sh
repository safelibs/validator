#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-rect
# @title: Pygame draw rect
# @description: Uses Pygame to run SDL draw rect behavior.
# @timeout: 180
# @tags: usage, headless, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    export PYGAME_HIDE_SUPPORT_PROMPT=1
python3 - <<'PY' "$tmpdir/out.bmp"
import os, pygame; os.environ['SDL_VIDEODRIVER']='dummy'; pygame.init(); s=pygame.Surface((10,10)); pygame.draw.rect(s,(0,0,255),(1,1,5,5)); print('pixel', s.get_at((2,2)))
PY
