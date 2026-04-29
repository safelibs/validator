#!/usr/bin/env bash
# @testcase: headless-event-timer
# @title: Headless event timer behavior
# @description: Runs SDL timer and event APIs under dummy video settings.
# @timeout: 120
# @tags: api, event

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export SDL_VIDEODRIVER=dummy; cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <stdio.h>
int main(void){if(SDL_Init(SDL_INIT_VIDEO|SDL_INIT_TIMER|SDL_INIT_EVENTS))return 1;SDL_Event e;e.type=SDL_USEREVENT;e.user.code=7;SDL_PushEvent(&e);int seen=0;Uint32 s=SDL_GetTicks();while(SDL_GetTicks()-s<1000){while(SDL_PollEvent(&e))if(e.type==SDL_USEREVENT)seen=1;if(seen)break;SDL_Delay(5);}printf("event-seen=%d\n",seen);SDL_Quit();return seen?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(sdl2-config --cflags --libs); "$tmpdir/t"
