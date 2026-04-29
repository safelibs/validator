#!/usr/bin/env bash
# @testcase: parser-emitter-roundtrip
# @title: YAML parser emitter round trip
# @description: Loads YAML into a document and emits it back through libyaml.
# @timeout: 120
# @tags: api, roundtrip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <yaml.h>
#include <stdio.h>
#include <string.h>
int main(void){const unsigned char in[]="name: alpha\nitems:\n - one\n";yaml_parser_t p;yaml_document_t d;yaml_emitter_t e;unsigned char out[4096];size_t w=0;yaml_parser_initialize(&p);yaml_parser_set_input_string(&p,in,strlen((char*)in));if(!yaml_parser_load(&p,&d))return 1;yaml_emitter_initialize(&e);yaml_emitter_set_output_string(&e,out,sizeof out,&w);if(!yaml_emitter_dump(&e,&d))return 2;yaml_emitter_delete(&e);yaml_parser_delete(&p);fwrite(out,1,w,stdout);return w?0:3;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lyaml; "$tmpdir/t"
