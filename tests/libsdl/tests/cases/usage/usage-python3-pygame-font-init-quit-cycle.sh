#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-init-quit-cycle
# @title: pygame font init/get_init/quit cycle
# @description: Cycles pygame.font.init and pygame.font.quit, asserting pygame.font.get_init transitions between True and False at each step.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-font-init-quit-cycle"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
# Avoid pygame.init() so we can cleanly drive font.init/quit ourselves.
pygame.font.quit()
assert pygame.font.get_init() in (False, 0), pygame.font.get_init()
pygame.font.init()
try:
    assert pygame.font.get_init(), pygame.font.get_init()
    pygame.font.quit()
    assert not pygame.font.get_init(), pygame.font.get_init()
    pygame.font.init()
    assert pygame.font.get_init(), pygame.font.get_init()
    print("font-cycle", bool(pygame.font.get_init()))
finally:
    pygame.font.quit()
PY
