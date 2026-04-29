#!/usr/bin/env bash
# @testcase: usage-python3-pygame-audio-dummy
# @title: Pygame audio dummy
# @description: Uses Pygame to run SDL audio dummy behavior.
# @timeout: 180
# @tags: usage, headless, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    export PYGAME_HIDE_SUPPORT_PROMPT=1
python3 - <<'PY' "$tmpdir/out.bmp"
import os, pygame; os.environ['SDL_AUDIODRIVER']='dummy'; pygame.mixer.init(frequency=22050, channels=1); print('mixer', pygame.mixer.get_init()); pygame.mixer.quit()
PY
