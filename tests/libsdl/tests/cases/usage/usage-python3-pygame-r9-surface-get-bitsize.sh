#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-surface-get-bitsize
# @title: Pygame Surface bitsize variants
# @description: Creates Surfaces with explicit depths and SRCALPHA flag and verifies get_bitsize / get_bytesize match expected values.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import pygame
pygame.init()
try:
    s32 = pygame.Surface((4, 4), 0, 32)
    assert s32.get_bitsize() == 32, s32.get_bitsize()
    assert s32.get_bytesize() == 4, s32.get_bytesize()
    s_alpha = pygame.Surface((4, 4), pygame.SRCALPHA, 32)
    assert s_alpha.get_bitsize() == 32
    assert s_alpha.get_flags() & pygame.SRCALPHA
finally:
    pygame.quit()
PY
