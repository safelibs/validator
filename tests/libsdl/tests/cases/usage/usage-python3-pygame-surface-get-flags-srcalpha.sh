#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-get-flags-srcalpha
# @title: pygame Surface get_flags SRCALPHA
# @description: Creates a Surface with the SRCALPHA flag and confirms Surface.get_flags() reports the flag bit while a plain surface created without the flag does not.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-get-flags-srcalpha"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    plain = pygame.Surface((4, 4))
    alpha = pygame.Surface((4, 4), flags=pygame.SRCALPHA)
    plain_flags = plain.get_flags()
    alpha_flags = alpha.get_flags()
    assert isinstance(plain_flags, int)
    assert isinstance(alpha_flags, int)
    assert alpha_flags & pygame.SRCALPHA, f"SRCALPHA missing from {alpha_flags:#x}"
    assert not (plain_flags & pygame.SRCALPHA), f"SRCALPHA unexpectedly set on plain surface: {plain_flags:#x}"
    print("flags", f"plain={plain_flags:#x}", f"alpha={alpha_flags:#x}")
finally:
    pygame.quit()
PY
