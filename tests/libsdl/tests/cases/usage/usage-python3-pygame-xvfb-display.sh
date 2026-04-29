#!/usr/bin/env bash
# @testcase: usage-python3-pygame-xvfb-display
# @title: Pygame xvfb display
# @description: Uses Pygame to run SDL xvfb display behavior.
# @timeout: 180
# @tags: usage, gui, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    export PYGAME_HIDE_SUPPORT_PROMPT=1
validator_run_xvfb python3 - <<'PY' "$tmpdir/out.bmp"
import pygame; pygame.display.init(); screen=pygame.display.set_mode((32,24)); print('display', screen.get_size()); pygame.display.quit()
PY
