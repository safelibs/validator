#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <yaml.h>
#include <stdio.h>
#include <string.h>
int main(void){const unsigned char in[]="first: &a {name: alpha}\nsecond: *a\n";yaml_parser_t p;yaml_event_t e;int n=0;yaml_parser_initialize(&p);yaml_parser_set_input_string(&p,in,strlen((char*)in));do{if(!yaml_parser_parse(&p,&e))return 1;if(e.type==YAML_ALIAS_EVENT)n++;yaml_event_type_t t=e.type;yaml_event_delete(&e);if(t==YAML_STREAM_END_EVENT)break;}while(1);yaml_parser_delete(&p);printf("aliases=%d\n",n);return n==1?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lyaml; "$tmpdir/t"
