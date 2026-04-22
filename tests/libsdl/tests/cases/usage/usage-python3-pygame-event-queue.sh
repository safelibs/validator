#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame

event_type = pygame.event.custom_type()
event = pygame.event.Event(event_type, code=7)
if event.type != event_type or getattr(event, "code", None) != 7:
    raise SystemExit("custom event payload did not round-trip")
print("event", event.type, event.code)
PY
