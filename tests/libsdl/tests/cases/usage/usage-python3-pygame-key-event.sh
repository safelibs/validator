#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy

python3 - <<'PY'
import pygame

expected_key = pygame.K_a
event = pygame.event.Event(pygame.KEYDOWN, key=expected_key)
event_name = pygame.event.event_name(event.type)
if event.type != pygame.KEYDOWN or getattr(event, "key", None) != expected_key:
    raise SystemExit("expected KEYDOWN for pygame.K_a")
if event_name != "KeyDown":
    raise SystemExit(f"unexpected key event name: {event_name}")
print("keydown", event.key, event_name)
PY
