#!/usr/bin/env bash
# @testcase: compile-link-smoke
# @title: json-c compile link smoke
# @description: Compiles a small program against json-c headers and library.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <json-c/json.h>
#include <stdio.h>
int main(void){printf("json-c version=%s\n",json_c_version());return json_c_version_num()>0?0:1;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs json-c); "$tmpdir/t"
