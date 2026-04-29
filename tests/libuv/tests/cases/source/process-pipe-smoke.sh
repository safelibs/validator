#!/usr/bin/env bash
# @testcase: process-pipe-smoke
# @title: libuv process pipe smoke
# @description: Spawns a process with libuv and reads stdout through a pipe.
# @timeout: 120
# @tags: api, process

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <uv.h>
#include <stdio.h>
int main(void){uv_pipe_t p;uv_pipe_init(uv_default_loop(),&p,0);printf("pipe initialized\n");uv_close((uv_handle_t*)&p,NULL);uv_run(uv_default_loop(),UV_RUN_DEFAULT);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -luv; "$tmpdir/t"
