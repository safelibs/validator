#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <uv.h>
#include <stdio.h>
static void cb(uv_timer_t*t){puts("timer fired");uv_timer_stop(t);uv_close((uv_handle_t*)t,NULL);}int main(void){uv_timer_t t;uv_timer_init(uv_default_loop(),&t);uv_timer_start(&t,cb,10,0);return uv_run(uv_default_loop(),UV_RUN_DEFAULT);}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -luv; "$tmpdir/t"
