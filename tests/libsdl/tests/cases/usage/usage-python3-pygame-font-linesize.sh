#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-linesize
# @title: pygame font linesize
# @description: Queries a pygame font line size and verifies it is positive and at least as tall as the font height.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-font-linesize"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    font = pygame.font.Font(None, 24)
    assert font.get_linesize() >= font.get_height() > 0
    print(font.get_linesize())
finally:
    pygame.quit()
PYCASE
