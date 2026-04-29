#!/usr/bin/env bash
# @testcase: loader-dumper-cases
# @title: YAML loader dumper cases
# @description: Loads multiple YAML documents and counts them through libyaml.
# @timeout: 120
# @tags: api, parser

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <yaml.h>
#include <stdio.h>
#include <string.h>
int main(void){const unsigned char in[]="---\na: 1\n---\nb: 2\n";yaml_parser_t p;yaml_document_t d;int n=0;yaml_parser_initialize(&p);yaml_parser_set_input_string(&p,in,strlen((char*)in));while(yaml_parser_load(&p,&d)){if(!yaml_document_get_root_node(&d))break;n++;yaml_document_delete(&d);}yaml_parser_delete(&p);printf("documents=%d\n",n);return n==2?0:1;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lyaml; "$tmpdir/t"
