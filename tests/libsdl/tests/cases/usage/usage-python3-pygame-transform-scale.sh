#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-scale
# @title: Pygame transform scale
# @description: Uses Pygame to run SDL transform scale behavior.
# @timeout: 180
# @tags: usage, headless, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    export PYGAME_HIDE_SUPPORT_PROMPT=1
python3 - <<'PY' "$tmpdir/out.bmp"
import os, pygame; os.environ['SDL_VIDEODRIVER']='dummy'; pygame.init(); s=pygame.Surface((4,4)); out=pygame.transform.scale(s,(8,8)); print('scaled', out.get_size())
PY
