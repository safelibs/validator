#!/usr/bin/env bash
# @testcase: usage-python3-pygame-key-name-a
# @title: pygame key.name returns "a" for K_a
# @description: Calls pygame.key.name(K_a) and verifies it returns the string "a", and that K_RETURN maps to a non-empty descriptive name.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-key-name-a"
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
    name = pygame.key.name(pygame.K_a)
    assert name == "a", f"expected 'a', got {name!r}"
    ret_name = pygame.key.name(pygame.K_RETURN)
    assert isinstance(ret_name, str) and ret_name, ret_name
    space_name = pygame.key.name(pygame.K_SPACE)
    assert isinstance(space_name, str) and space_name
    print("key.name", name, ret_name, space_name)
finally:
    pygame.quit()
PY
