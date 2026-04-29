#!/usr/bin/env bash
# @testcase: invalid-yaml-rejection
# @title: Invalid YAML rejection
# @description: Requires libyaml parser load to fail on malformed YAML input.
# @timeout: 120
# @tags: api, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <yaml.h>
#include <stdio.h>
#include <string.h>
int main(void){const unsigned char in[]="key: [unterminated\n";yaml_parser_t p;yaml_document_t d;yaml_parser_initialize(&p);yaml_parser_set_input_string(&p,in,strlen((char*)in));int ok=yaml_parser_load(&p,&d);if(ok){yaml_document_delete(&d);return 1;}printf("error=%d\n",p.error);yaml_parser_delete(&p);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lyaml; "$tmpdir/t"
