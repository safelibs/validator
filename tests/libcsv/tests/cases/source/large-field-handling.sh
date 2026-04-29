#!/usr/bin/env bash
# @testcase: large-field-handling
# @title: Large field handling
# @description: Parses a large field and confirms the callback receives all bytes.
# @timeout: 120
# @tags: api, large-field

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <csv.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static size_t seen;static void cb(void*s,size_t l,void*d){(void)s;(void)d;seen=l;}int main(void){size_t n=200000;char*in=malloc(n+2);memset(in,'a',n);in[n]='\n';in[n+1]=0;struct csv_parser p;csv_init(&p,0);if(csv_parse(&p,in,n+1,cb,NULL,NULL)!=n+1)return 1;csv_fini(&p,cb,NULL,NULL);csv_free(&p);free(in);printf("large=%zu\n",seen);return seen==n?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcsv; "$tmpdir/t"
