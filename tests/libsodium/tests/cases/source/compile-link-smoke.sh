#!/usr/bin/env bash
# @testcase: compile-link-smoke
# @title: libsodium compile link smoke
# @description: Compiles a libsodium program and reports the installed library version.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <sodium.h>
#include <stdio.h>
int main(void){if(sodium_init()<0)return 1;printf("sodium=%s\n",sodium_version_string());return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lsodium; "$tmpdir/t"
