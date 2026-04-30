#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-lock-unlock
# @title: Pygame surface lock unlock pair
# @description: Performs an explicit pygame.Surface.lock/unlock pair, verifying get_locked transitions correctly across the call boundary on a fresh Surface.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-lock-unlock"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.init()
try:
    surface = pygame.Surface((16, 16))
    assert surface.get_locked() is False, "freshly allocated surface should start unlocked"

    surface.lock()
    try:
        assert surface.get_locked() is True, "surface should report locked after .lock()"
        # While locked, locks() should reflect the explicit user-level lock.
        locks = surface.get_locks()
        assert isinstance(locks, tuple), type(locks)
    finally:
        surface.unlock()

    assert surface.get_locked() is False, "surface should be unlocked after .unlock()"

    print(case_id, "ok")
finally:
    pygame.quit()
PY
