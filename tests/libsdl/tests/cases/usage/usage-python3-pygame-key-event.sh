#!/usr/bin/env bash
# @testcase: usage-python3-pygame-key-event
# @title: Pygame key event dispatch
# @description: Posts a Pygame keydown event and verifies the SDL-backed queue returns the same key.
# @timeout: 180
# @tags: usage, headless, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy

python3 - <<'PY'
import pygame

pygame.init()
try:
    pygame.event.clear()
    expected_key = pygame.K_a
    pygame.event.post(pygame.event.Event(pygame.KEYDOWN, key=expected_key))
    pygame.event.pump()
    for event in pygame.event.get():
        if event.type == pygame.KEYDOWN and getattr(event, "key", None) == expected_key:
            print("keydown", event.key)
            break
    else:
        raise SystemExit("expected KEYDOWN for pygame.K_a")
finally:
    pygame.quit()
PY
