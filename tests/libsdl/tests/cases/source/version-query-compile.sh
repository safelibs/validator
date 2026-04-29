#!/usr/bin/env bash
# @testcase: version-query-compile
# @title: SDL version query compile
# @description: Compiles a small SDL program that reports version and platform details.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <stdio.h>
int main(void){SDL_version v;SDL_GetVersion(&v);printf("SDL %u.%u.%u platform=%s\n",v.major,v.minor,v.patch,SDL_GetPlatform());return v.major==2?0:1;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(sdl2-config --cflags --libs); "$tmpdir/t"
