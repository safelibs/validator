#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    cat >"$tmpdir/t.c" <<'C'
#include <csv.h>
#include <stdio.h>
#include <string.h>
struct C{int f;int r;}; static void fcb(void*s,size_t l,void*d){((struct C*)d)->f++; printf("field=%.*s
",(int)l,(char*)s);} static void rcb(int ch,void*d){(void)ch;((struct C*)d)->r++; puts("row");}
int main(void){const char in[]="name,score
alpha,42
"; struct C c={0,0}; struct csv_parser p; csv_init(&p,0); csv_parse(&p,in,strlen(in),fcb,rcb,&c); csv_fini(&p,fcb,rcb,&c); csv_free(&p); printf("fields=%d rows=%d
",c.f,c.r); return c.f==4?0:1;}
C
    gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcsv
    "$tmpdir/t"
