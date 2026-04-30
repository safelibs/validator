#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-get-alpha-default
# @title: pygame Surface get_alpha defaults
# @description: Verifies the default alpha values reported by Surface.get_alpha() for an opaque RGB surface and an SRCALPHA surface freshly created from pygame.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-get-alpha-default"
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
    plain = pygame.Surface((2, 2))
    alpha = pygame.Surface((2, 2), flags=pygame.SRCALPHA)
    plain_alpha = plain.get_alpha()
    alpha_alpha = alpha.get_alpha()
    # Pygame's documented default for both: a freshly-constructed Surface
    # reports alpha=255 (None for surfaces with no alpha capability is also
    # accepted on the plain RGB path on some SDL builds).
    assert plain_alpha in (None, 255), plain_alpha
    assert alpha_alpha == 255, alpha_alpha
    print("alpha", "plain", plain_alpha, "srcalpha", alpha_alpha)
finally:
    pygame.quit()
PY
