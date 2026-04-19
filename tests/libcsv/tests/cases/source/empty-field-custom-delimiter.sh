#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <csv.h>
#include <stdio.h>
#include <string.h>
struct C{int f,e;};static void cb(void*s,size_t l,void*d){struct C*c=d;c->f++;if(!l)c->e++;printf("field[%zu]=%.*s\n",l,(int)l,(char*)s);}int main(void){const char in[]="a;;\"c;d\"\n";struct csv_parser p;struct C c={0,0};csv_init(&p,0);csv_set_delim(&p,';');csv_parse(&p,in,strlen(in),cb,NULL,&c);csv_fini(&p,cb,NULL,&c);csv_free(&p);printf("fields=%d empty=%d\n",c.f,c.e);return c.f==3&&c.e==1?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcsv; "$tmpdir/t"
