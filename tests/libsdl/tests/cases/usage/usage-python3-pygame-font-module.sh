#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-module
# @title: Pygame font module
# @description: Uses Pygame to run SDL font module behavior.
# @timeout: 180
# @tags: usage, headless, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    export PYGAME_HIDE_SUPPORT_PROMPT=1
python3 - <<'PY' "$tmpdir/out.bmp"
import os, pygame; os.environ['SDL_VIDEODRIVER']='dummy'; pygame.init(); pygame.font.init(); f=pygame.font.Font(None,16); s=f.render('ok', True, (255,255,255)); print('text', s.get_size())
PY
