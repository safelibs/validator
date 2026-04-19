#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    export PYGAME_HIDE_SUPPORT_PROMPT=1
python3 - <<'PY' "$tmpdir/out.bmp"
import os, pygame; os.environ['SDL_VIDEODRIVER']='dummy'; pygame.init(); pygame.event.post(pygame.event.Event(pygame.USEREVENT, code=7)); e=pygame.event.poll(); print('event', e.type, getattr(e,'code',None)); raise SystemExit(0 if e.type == pygame.USEREVENT else 1)
PY