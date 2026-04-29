#!/usr/bin/env bash
# @testcase: compile-link-smoke
# @title: libyaml compile link smoke
# @description: Compiles a minimal program against the public libyaml headers.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <yaml.h>
#include <stdio.h>
int main(void){yaml_parser_t p;if(!yaml_parser_initialize(&p))return 1;puts("libyaml parser initialized");yaml_parser_delete(&p);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lyaml; "$tmpdir/t"
