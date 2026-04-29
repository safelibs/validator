#!/usr/bin/env bash
# @testcase: dns-getaddrinfo
# @title: libuv DNS getaddrinfo
# @description: Resolves localhost through libuv getaddrinfo request handling APIs.
# @timeout: 120
# @tags: api, dns

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <uv.h>
#include <stdio.h>
#include <stdlib.h>
static int ok;static void cb(uv_getaddrinfo_t*r,int s,struct addrinfo*a){if(s<0)exit(1);ok=1;printf("family=%d\n",a->ai_family);uv_freeaddrinfo(a);}int main(void){uv_getaddrinfo_t r;struct addrinfo h={0};if(uv_getaddrinfo(uv_default_loop(),&r,cb,"localhost",NULL,&h))return 1;uv_run(uv_default_loop(),UV_RUN_DEFAULT);return ok?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -luv; "$tmpdir/t"
