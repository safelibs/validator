#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <csv.h>
#include <stdio.h>
#include <string.h>
struct C{int f,r;};static void fcb(void*s,size_t l,void*d){struct C*c=d;c->f++;printf("field:%.*s\n",(int)l,(char*)s);}static void rcb(int ch,void*d){(void)ch;((struct C*)d)->r++;puts("row");}int main(void){const char in[]="name,score\nalpha,42\n";struct csv_parser p;struct C c={0,0};csv_init(&p,0);if(csv_parse(&p,in,strlen(in),fcb,rcb,&c)!=strlen(in))return 1;csv_fini(&p,fcb,rcb,&c);csv_free(&p);printf("fields=%d rows=%d\n",c.f,c.r);return c.f==4&&c.r==2?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcsv; "$tmpdir/t"
